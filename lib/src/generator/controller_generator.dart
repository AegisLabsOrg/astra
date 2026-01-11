import 'package:analyzer/dart/element/type.dart'; // Added for DartType
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import '../meta/annotations.dart';

class ControllerGenerator extends GeneratorForAnnotation<Controller> {
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

    final buffer = StringBuffer();

    buffer.writeln('extension ${className}Routes on $className {');
    buffer.writeln(
      '  void registerRoutes(TrieRouter router, OpenApiRegistry openApi) {',
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
        if (typeName == 'Get') httpMethod = 'HttpMethod.get';
        if (typeName == 'Post') httpMethod = 'HttpMethod.post';
        if (typeName == 'Put') httpMethod = 'HttpMethod.put';
        if (typeName == 'Delete') httpMethod = 'HttpMethod.delete';
        if (typeName == 'Patch') httpMethod = 'HttpMethod.patch';

        if (httpMethod != null) {
          final reader = ConstantReader(computed);
          final path = reader.peek('path')?.stringValue ?? '';
          final fullPath = '$controllerPath$path'.replaceAll('//', '/');

          // OpenAPI Generation
          final openApiParams = <String>[];
          String? openApiRequestBody;

          for (final param in method.formalParameters) {
            final pName = param.name;
            final pType = param.type.getDisplayString(withNullability: false);
            final oType = (['int', 'double', 'num'].contains(pType))
                ? 'integer'
                : (pType == 'bool' ? 'boolean' : 'string');

            final pAnno = _getAnnotation(param, 'Path');
            if (pAnno != null) {
              final r = ConstantReader(pAnno);
              final name = r.peek('name')?.stringValue ?? pName;
              openApiParams.add(
                "OpenApiParameter(name: '$name', location: 'path', required: true, type: '$oType')",
              );
            }

            final qAnno = _getAnnotation(param, 'Query');
            if (qAnno != null) {
              final r = ConstantReader(qAnno);
              final name = r.peek('name')?.stringValue ?? pName;
              openApiParams.add(
                "OpenApiParameter(name: '$name', location: 'query', required: ${!param.isOptional}, type: '$oType')",
              );
            }

            final bAnno = _getAnnotation(param, 'Body');
            if (bAnno != null) {
              // Simple schema usage
              openApiRequestBody =
                  " {'content': {'application/json': {'schema': {'type': 'object', 'title': '$pType'}}}}";
            }
          }

          final openApiMethodStr = typeName!.toUpperCase();
          buffer.writeln("    openApi.registerRoute(");
          buffer.writeln("      '$openApiMethodStr',");
          buffer.writeln("      '$fullPath',");
          buffer.writeln("      OpenApiOperation(");
          buffer.writeln("        operationId: '${method.name}',");
          if (openApiParams.isNotEmpty) {
            buffer.writeln(
              "        parameters: [${openApiParams.join(', ')}],",
            );
          }
          if (openApiRequestBody != null) {
            buffer.writeln("        requestBody: $openApiRequestBody,");
          }
          buffer.writeln("      ),");
          buffer.writeln("    );");

          // Generate the wrapper closure: (Request req, Map<String, String> pathParams)
          buffer.writeln(
            "    router.register($httpMethod, '$fullPath', (Request req, Map<String, String> pathParams) async {",
          );

          final params = method.formalParameters;
          final argList = <String>[];

          for (final param in params) {
            String? extractedArg;

            // 1. Check for @Path('name')
            final pathAnno = _getAnnotation(param, 'Path');
            if (pathAnno != null) {
              final reader = ConstantReader(pathAnno);
              final name = reader.peek('name')?.stringValue ?? param.name;
              final rawValue = "pathParams['$name']!";
              extractedArg = _convertType(rawValue, param.type);
            }

            // 2. Check for @Query('name')
            if (extractedArg == null) {
              final queryAnno = _getAnnotation(param, 'Query');
              if (queryAnno != null) {
                final reader = ConstantReader(queryAnno);
                final name = reader.peek('name')?.stringValue ?? param.name;
                final rawValue = "req.url.queryParameters['$name']!";
                extractedArg = _convertType(rawValue, param.type);
              }
            }

            // 3. Check for @Body()
            if (extractedArg == null) {
              final bodyAnno = _getAnnotation(param, 'Body');
              if (bodyAnno != null) {
                final typeName = param.type.getDisplayString(
                  withNullability: false,
                );

                // We define a block variable name based on param name
                buffer.writeln(
                  "      final bodyBytes_${param.name} = await req.readAsString();",
                );
                buffer.writeln(
                  "      final bodyJson_${param.name} = jsonDecode(bodyBytes_${param.name});",
                );
                buffer.writeln(
                  "      final ${param.name}Arg = $typeName.fromJson(bodyJson_${param.name});",
                );

                extractedArg = "${param.name}Arg";
              }
            }

            // 4. Special Types: Request
            if (extractedArg == null) {
              final type = param.type.getDisplayString(withNullability: false);
              if (type == 'Request') {
                extractedArg = 'req';
              }
            }

            // 4. Fallback / TODO: Body & DI
            if (extractedArg == null) {
              extractedArg =
                  "throw UnimplementedError('Cannot resolve parameter ${param.name}')";
            }

            argList.add(extractedArg);
          }

          // Smart Return Values logic
          final returnType = method.returnType.getDisplayString(
            withNullability: false,
          );

          if (returnType == 'void' || returnType == 'Future<void>') {
            buffer.writeln(
              "      await this.${method.name}(${argList.join(', ')});",
            );
            buffer.writeln("      return Response.ok(null);");
          } else {
            buffer.writeln(
              "      final result = await this.${method.name}(${argList.join(', ')});",
            );

            if (returnType == 'Response' || returnType == 'Future<Response>') {
              buffer.writeln("      return result;");
            } else {
              // Assume JSON serialization for any other type
              buffer.writeln(
                "      return Response.ok(jsonEncode(result), headers: {'content-type': 'application/json'});",
              );
            }
          }

          buffer.writeln("    });");
        }
      }
    }

    buffer.writeln('  }');
    buffer.writeln('}');

    // GENERATE DI FACTORY
    // void registerUserController(AstraApp app) {
    //    final controller = UserController(app.container.resolve<UserService>());
    //    controller.registerRoutes(app.router);
    // }

    // Find the unnamed (default) constructor
    final constructor = element.unnamedConstructor;
    if (constructor != null) {
      final diParams = <String>[];
      for (final param in constructor.formalParameters) {
        final type = param.type.getDisplayString(withNullability: false);
        // Assuming strict type registration
        diParams.add("app.container.resolve<$type>()");
      }

      buffer.writeln('');
      buffer.writeln('void register${className}(AstraApp app) {');
      buffer.writeln(
        '  final controller = $className(${diParams.join(', ')});',
      );
      buffer.writeln(
        '  controller.registerRoutes(app.router, app.openApiRegistry);',
      );
      buffer.writeln('}');
    }

    return buffer.toString();
  }

  /// Helper to get a specific annotation from a parameter
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

  String _convertType(String expression, DartType type) {
    if (type.isDartCoreInt) {
      return "int.parse($expression)";
    }
    if (type.isDartCoreDouble) {
      return "double.parse($expression)";
    }
    if (type.isDartCoreBool) {
      return "$expression == 'true'";
    }
    return expression; // Default as String
  }
}
