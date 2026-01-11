import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import '../meta/annotations.dart';

class ClientGenerator extends GeneratorForAnnotation<Controller> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Controller can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final controllerPath = annotation.read('path').stringValue;
    final clientName = '${className}Client';

    final buffer = StringBuffer();

    // Imports
    // We assume the file this is generated from is available, so we import it.
    // However, since this is a separate library file, we need to know the import URI of the source.
    // source_gen's LibraryBuilder usually handles part files well, but for a separate file,
    // we might need to be careful about imports.
    // For now, we will generate the class and assume the user will fix imports or we generated it as a part?
    // If we generate as a part, we can't easily use it in another project.
    // If we generate as a library, we need to import the types (DTOs).
    // Let's rely on the user to export the DTOs or be in the same package.
    // We will generate `part of` if we use SharedPartBuilder, but we want a standalone file.
    // Let's try to generate a class that can be copy-pasted or used if in the same package.

    // Actually, making it a `part` file with a different name is tricky.
    // Let's try to make it a standalone library code.

    buffer.writeln("import 'dart:convert';");
    buffer.writeln("import 'package:http/http.dart' as http;");
    buffer.writeln(
      "import 'package:web_socket_channel/web_socket_channel.dart';",
    );
    // Import the source file to access types
    final assetId = buildStep.inputId;
    final fileName = assetId.pathSegments.last;
    buffer.writeln("import '$fileName';");

    buffer.writeln('class $clientName {');
    buffer.writeln('  final String baseUrl;');
    buffer.writeln('  final http.Client httpClient;');
    buffer.writeln('');
    buffer.writeln(
      '  $clientName(this.baseUrl, {http.Client? client}) : httpClient = client ?? http.Client();',
    );

    for (final method in element.methods) {
      final List<ElementAnnotation> metadataList = method.metadata.annotations;
      for (final metadata in metadataList) {
        final computed = metadata.computeConstantValue();
        if (computed == null) continue;

        final typeName = computed.type?.getDisplayString(
          withNullability: false,
        );

        String? httpMethod;
        bool isWebSocket = false;

        if (typeName == 'Get') httpMethod = 'GET';
        if (typeName == 'Post') httpMethod = 'POST';
        if (typeName == 'Put') httpMethod = 'PUT';
        if (typeName == 'Delete') httpMethod = 'DELETE';
        if (typeName == 'Patch') httpMethod = 'PATCH';
        if (typeName == 'WebSocketRoute') {
          isWebSocket = true;
        }

        if (httpMethod != null || isWebSocket) {
          final reader = ConstantReader(computed);
          final path = reader.peek('path')?.stringValue ?? '';
          // Construct the path with string interpolation for params
          // /ws/chat/:room -> /ws/chat/$room
          // We need to parse :param

          String processedPath = '$controllerPath$path'.replaceAll('//', '/');

          final methodParams = <String>[];
          final queryParams = <String>[];
          String? bodyParam;

          for (final param in method.formalParameters) {
            final pName = param.name;
            final pType = param.type.getDisplayString(withNullability: false);

            // Check annotations
            final pathAnno = _getAnnotation(param, 'Path');
            final queryAnno = _getAnnotation(param, 'Query');
            final bodyAnno = _getAnnotation(param, 'Body');

            if (pathAnno != null) {
              final r = ConstantReader(pathAnno);
              final name = r.peek('name')?.stringValue ?? pName;
              // Replace :name with $pName
              processedPath = processedPath.replaceAll(':$name', '\$$pName');
              methodParams.add('$pType $pName');
            } else if (queryAnno != null) {
              final r = ConstantReader(queryAnno);
              final name = r.peek('name')?.stringValue ?? pName;
              queryParams.add("'$name': $pName.toString()");
              methodParams.add('$pType $pName');
            } else if (bodyAnno != null) {
              bodyParam = pName;
              methodParams.add('$pType $pName');
            } else if (isWebSocket && pType == 'WebSocketChannel') {
              // Ignore channel param in client method signature, we return it or use it?
              // For WebSocket client, we typically return the Stream/Sink or the Channel.
            } else if (isWebSocket) {
              // Other params for WebSocket might be query or path
              // If no annotation, assume path if it matches?
              // For now stick to strict annotations or assume it's like HTTP
            }
          }

          if (isWebSocket) {
            buffer.writeln('');
            buffer.writeln(
              '  WebSocketChannel ${method.name}(${methodParams.join(', ')}) {',
            );
            buffer.writeln(
              "    final uri = Uri.parse('\$baseUrl$processedPath');",
            );
            // Handle query params for WS?
            if (queryParams.isNotEmpty) {
              buffer.writeln(
                "    final urlWitQuery = uri.replace(queryParameters: {${queryParams.join(', ')}});",
              );
              buffer.writeln(
                "    return WebSocketChannel.connect(urlWitQuery);",
              );
            } else {
              buffer.writeln("    return WebSocketChannel.connect(uri);");
            }
            buffer.writeln('  }');
            continue; // Done for WS
          }

          // HTTP Generation
          final returnType = method.returnType.getDisplayString(
            withNullability: false,
          );
          // Unwrap Future
          String innerReturnType = 'void';
          if (returnType.startsWith('Future<')) {
            innerReturnType = returnType.substring(7, returnType.length - 1);
          } else if (returnType != 'void') {
            innerReturnType = returnType;
          }

          buffer.writeln('');
          buffer.writeln(
            '  Future<$innerReturnType> ${method.name}(${methodParams.join(', ')}) async {',
          );
          buffer.writeln(
            "    final uri = Uri.parse('\$baseUrl$processedPath');",
          );
          if (queryParams.isNotEmpty) {
            buffer.writeln(
              "    final url = uri.replace(queryParameters: {${queryParams.join(', ')}});",
            );
          } else {
            buffer.writeln("    final url = uri;");
          }

          buffer.writeln(
            "    final response = await httpClient.${httpMethod!.toLowerCase()}(",
          );
          buffer.writeln("      url,");
          if (bodyParam != null) {
            buffer.writeln(
              "      headers: {'content-type': 'application/json'},",
            );
            buffer.writeln("      body: jsonEncode($bodyParam),");
          }
          buffer.writeln("    );");

          buffer.writeln("    if (response.statusCode >= 400) {");
          buffer.writeln(
            "      throw Exception('API Error \${response.statusCode}: \${response.body}');",
          );
          buffer.writeln("    }");

          if (innerReturnType != 'void') {
            if (innerReturnType == 'int')
              buffer.writeln("    return int.parse(response.body);");
            else if (innerReturnType == 'double')
              buffer.writeln("    return double.parse(response.body);");
            else if (innerReturnType == 'String')
              buffer.writeln("    return response.body;");
            else if (innerReturnType == 'bool')
              buffer.writeln("    return response.body == 'true';");
            else if (innerReturnType.startsWith('List<')) {
              // List<MyObj> -> MyObj
              final generic = innerReturnType.substring(
                5,
                innerReturnType.length - 1,
              );
              buffer.writeln(
                "    final List<dynamic> json = jsonDecode(response.body);",
              );
              buffer.writeln(
                "    return json.map((e) => $generic.fromJson(e)).toList();",
              );
            } else {
              // Object
              buffer.writeln(
                "    return $innerReturnType.fromJson(jsonDecode(response.body));",
              );
            }
          }

          buffer.writeln('  }');
        }
      }
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  DartObject? _getAnnotation(
    FormalParameterElement param,
    String annotationName,
  ) {
    for (final meta in param.metadata.annotations) {
      final obj = meta.computeConstantValue();
      final type = obj?.type?.getDisplayString(withNullability: false);
      if (type == annotationName) {
        return obj;
      }
    }
    return null;
  }
}
