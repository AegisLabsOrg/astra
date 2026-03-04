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

        final typeName = computed.type?.getDisplayString();

        String? httpMethod;
        bool isWebSocket = false;
        if (typeName == 'Get') httpMethod = 'HttpMethod.get';
        if (typeName == 'Post') httpMethod = 'HttpMethod.post';
        if (typeName == 'Put') httpMethod = 'HttpMethod.put';
        if (typeName == 'Delete') httpMethod = 'HttpMethod.delete';
        if (typeName == 'Patch') httpMethod = 'HttpMethod.patch';
        if (typeName == 'WebSocketRoute') {
          httpMethod = 'HttpMethod.get';
          isWebSocket = true;
        }

        if (httpMethod != null) {
          final reader = ConstantReader(computed);
          final path = reader.peek('path')?.stringValue ?? '';
          final fullPath = '$controllerPath$path'.replaceAll('//', '/');

          // OpenAPI Generation
          final openApiParams = <String>[];
          String? openApiRequestBody;

          for (final param in method.formalParameters) {
            final pName = param.name;
            final pType = param.type.getDisplayString();
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

          String openApiMethodStr;
          if (isWebSocket) {
            openApiMethodStr = 'GET';
          } else {
            openApiMethodStr = typeName!.toUpperCase();
          }
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

          if (isWebSocket) {
            buffer.writeln(
              "      final wsHandler = webSocketHandler((WebSocketChannel wsChannel, String? protocol) {",
            );
          }

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
                if (isWebSocket) {
                  extractedArg =
                      "throw UnimplementedError('Body not supported in WebSocketRoute')";
                } else {
                  final typeName = param.type.getDisplayString();

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
            }

            // 4. Special Types: Request
            if (extractedArg == null) {
              final type = param.type.getDisplayString();
              if (type == 'Request') {
                extractedArg = 'req';
              }
              // 5. Special Types: WebSocketChannel
              if (type == 'WebSocketChannel') {
                extractedArg = 'wsChannel';
              }
            }

            // 6. Fallback / TODO: Body & DI
            extractedArg ??=
                "throw UnimplementedError('Cannot resolve parameter ${param.name}')";

            argList.add(extractedArg);
          }

          if (isWebSocket) {
            buffer.writeln("      this.${method.name}(${argList.join(', ')});");
            buffer.writeln("      });");
            buffer.writeln("      return wsHandler(req);");
          } else {
            // Smart Return Values logic
            final returnType = method.returnType.getDisplayString();

            if (returnType == 'void' || returnType == 'Future<void>') {
              buffer.writeln(
                "      await this.${method.name}(${argList.join(', ')});",
              );
              buffer.writeln("      return Response.ok(null);");
            } else {
              buffer.writeln(
                "      final result = await this.${method.name}(${argList.join(', ')});",
              );

              if (returnType == 'Response' ||
                  returnType == 'Future<Response>') {
                buffer.writeln("      return result;");
              } else {
                // Assume JSON serialization for any other type
                buffer.writeln(
                  "      return Response.ok(jsonEncode(result), headers: {'content-type': 'application/json'});",
                );
              }
            }
          }

          buffer.writeln("    });");
        }
      }
    }

    buffer.writeln('  }');
    buffer.writeln('}');

    // GENERATE DI FACTORY
    // We generate a helper function to register the controller.
    // If the controller has dependencies, strict type registration is used.
    //
    // New Feature: Support for Scoped Controllers.
    // By default, we register as a singleton to keep backward compatibility and performance for stateless controllers.
    // But if a controller needs per-request scope, we should register it as a factory.
    // However, AstraApp structure currently expects "registerEverythingAtStartup".
    //
    // To support Scoped Controllers properly:
    // 1. We register a "ControllerFactory" in the container? No, the router needs to invoke it.
    // 2. The router handler needs to resolve the controller from the REQUEST scope.

    // Let's change the strategy:
    // The generated handler in `registerRoutes` is a closure: (Request req, Map pathParams) async { ... }
    // Inside this closure, we have access to `req.context['astra.container']`.
    //
    // If we want the controller to be scoped, we should NOT use `this.method(...)`.
    // Instead, we should resolve the controller from the container inside the handler!
    //
    // But `registerRoutes` is an extension method on an *instance*.
    // This implies an instance IS ALREADY CREATED.
    //
    // If we want Scoped Controllers, we need a static registration method that doesn't depend on an instance.
    //
    // Let's create `register${className}Routes` as a top-level function instead of an extension method on an instance?
    // Or keep the extension method for Singletons, and add a static helper for Scoped?
    //
    // Let's stick to the current pattern but enhance it.
    // The generated `register$className` function currently creates an instance and calls registerRoutes.

    // PROPOSAL:
    // Generate a new top-level function: `register${className}Controller(AstraApp app)`.
    // This function will register the loop-back handlers to the router.
    // Inside the handlers, it will resolve the controller from the scope.

    buffer.writeln('');
    buffer.writeln('void register$className(AstraApp app) {');

    // Register the controller class itself in the container as a Factory (Transient/Scoped)
    // We'll use "transient" (factory) so it's created fresh when resolved from validity scope.
    // Wait, if we want it to be scoped (shared within request), we use scoped.
    // For now, let's default to 'Scoped' if it has dependencies, or just register it.

    // Find constructor deps
    final constructor = element.unnamedConstructor;
    final diParams = <String>[];
    if (constructor != null) {
      for (final param in constructor.formalParameters) {
        final type = param.type.getDisplayString();
        diParams.add("c.resolve<$type>()");
      }
    }

    // Register the controller factory in the container
    buffer.writeln(
      '  app.container.registerFactory<$className>((c) => $className(${diParams.join(', ')}), lifetime: ServiceLifetime.scoped);',
    );

    // Register routes
    // Note: We are NOT using the extension method on 'this' anymore for the router handlers.
    // We are generating a standalone registration that resolves 'this' from scope.

    buffer.writeln('  final router = app.router;');
    buffer.writeln('  final openApi = app.openApiRegistry;');

    for (final method in element.methods) {
      final List<ElementAnnotation> metadataList = method.metadata.annotations;
      for (final metadata in metadataList) {
        final computed = metadata.computeConstantValue();
        if (computed == null) continue;

        final typeName = computed.type?.getDisplayString();

        String? httpMethod;
        bool isWebSocket = false;
        if (typeName == 'Get') httpMethod = 'HttpMethod.get';
        if (typeName == 'Post') httpMethod = 'HttpMethod.post';
        if (typeName == 'Put') httpMethod = 'HttpMethod.put';
        if (typeName == 'Delete') httpMethod = 'HttpMethod.delete';
        if (typeName == 'Patch') httpMethod = 'HttpMethod.patch';
        if (typeName == 'WebSocketRoute') {
          httpMethod = 'HttpMethod.get';
          isWebSocket = true;
        }

        if (httpMethod != null) {
          final reader = ConstantReader(computed);
          final path = reader.peek('path')?.stringValue ?? '';
          final fullPath = '$controllerPath$path'.replaceAll('//', '/');

          // OpenAPI (Same as before)
          // ... (We should probably refactor this duplication, but for now copypasta logic is safer)
          // OpenAPI Generation
          final openApiParams = <String>[];
          String? openApiRequestBody;

          for (final param in method.formalParameters) {
            final pName = param.name;
            final pType = param.type.getDisplayString();
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

          String openApiMethodStr;
          if (isWebSocket) {
            openApiMethodStr = 'GET';
          } else {
            openApiMethodStr = typeName!.toUpperCase();
          }
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

          // ROUTE HANDLER
          buffer.writeln(
            "    router.register($httpMethod, '$fullPath', (Request req, Map<String, String> pathParams) async {",
          );
          // RESOLVE CONTROLLER
          buffer.writeln("      final context = Context(req);");
          buffer.writeln(
            "      final controller = context.container.resolve<$className>();",
          );

          if (isWebSocket) {
            buffer.writeln(
              "      final wsHandler = webSocketHandler((WebSocketChannel wsChannel, String? protocol) {",
            );
          }

          // ARGUMENT PARSING
          final params = method.formalParameters;
          final argList = <String>[];

          for (final param in params) {
            String? extractedArg;
            String? location;

            // 1. Check for @Path('name')
            final pathAnno = _getAnnotation(param, 'Path');
            if (pathAnno != null) {
              final reader = ConstantReader(pathAnno);
              final name = reader.peek('name')?.stringValue ?? param.name;
              final rawValue = "pathParams['$name']!";
              extractedArg = _convertType(rawValue, param.type);
              location = 'path';
            }

            // 2. Check for @Query('name')
            if (extractedArg == null) {
              final queryAnno = _getAnnotation(param, 'Query');
              if (queryAnno != null) {
                final reader = ConstantReader(queryAnno);
                final name = reader.peek('name')?.stringValue ?? param.name;
                // Handle optionals
                if (param.isOptional) {
                  final rawValue = "req.url.queryParameters['$name']";
                  // If rawValue is null, pass null or default?
                  // Dart optional parameters handle null if nullable.
                  extractedArg = _convertType(
                    rawValue,
                    param.type,
                    isOptional: true,
                  );
                } else {
                  final rawValue = "req.url.queryParameters['$name']!";
                  extractedArg = _convertType(rawValue, param.type);
                }
                location = 'query';
              }
            }

            // 3. Check for @Body()
            if (extractedArg == null) {
              final bodyAnno = _getAnnotation(param, 'Body');
              if (bodyAnno != null) {
                if (isWebSocket) {
                  extractedArg =
                      "throw UnimplementedError('Body not supported in WebSocketRoute')";
                } else {
                  final typeName = param.type.getDisplayString();
                  buffer.writeln(
                    "      final bodyBytes_${param.name} = await req.readAsString();",
                  );
                  buffer.writeln(
                    "      final bodyJson_${param.name} = jsonDecode(bodyBytes_${param.name});",
                  );
                  buffer.writeln(
                    "      late final $typeName arg_${param.name};",
                  );
                  buffer.writeln("      try {");
                  buffer.writeln(
                    "        arg_${param.name} = $typeName.fromJson(bodyJson_${param.name});",
                  );
                  buffer.writeln("      } catch (e) {");
                  buffer.writeln(
                    "        throw ValidationException('${param.name}', 'Invalid body format: \$e');",
                  );
                  buffer.writeln("      }");

                  // ADD VALIDATION HERE?
                  // Ideally we'd call Validator.validate(..., ${param.name}Arg);
                  // But we don't know the constraints unless we inspect the DTO class here.
                  // Since we are in separate library, introspection is hard without ResolvedLibrary.
                  // For now, let's assume the user calls .validate() inside the handler or we rely on DTO fromJson to throw?
                  // Or we can generate a check if the DTO has a 'validate' method?

                  extractedArg = "arg_${param.name}";
                  location = 'body';
                }
              }
            }

            // 4. Special Types: Request
            if (extractedArg == null) {
              final type = param.type.getDisplayString();
              if (type == 'Request') {
                extractedArg = 'req';
                location = 'request';
              }
              if (type == 'Context') {
                extractedArg = 'context'; // Inject context!
                location = 'context';
              }
              if (type == 'WebSocketChannel') {
                extractedArg = 'wsChannel';
                location = 'websocket';
              }
            }

            if (location == 'path' || location == 'query') {
              // Wrap extractedArg in a strong try-catch for correct exception mapping
              final argVar = "arg_${param.name}";
              buffer.writeln(
                "      late final ${param.type.getDisplayString()} $argVar;",
              );
              buffer.writeln("      try {");
              buffer.writeln("        $argVar = $extractedArg;");
              buffer.writeln("      } catch (e) {");
              buffer.writeln(
                "        throw ValidationException('${param.name}', 'Invalid format for $location parameter: ${param.name}');",
              );
              buffer.writeln("      }");
              extractedArg = argVar;
            }

            extractedArg ??=
                "throw UnimplementedError('Cannot resolve parameter ${param.name}')";
            argList.add(extractedArg);
          }

          // CALL CONTROLLER METHOD
          if (isWebSocket) {
            buffer.writeln(
              "      controller.${method.name}(${argList.join(', ')});",
            );
            buffer.writeln("      });");
            buffer.writeln("      return wsHandler(req);");
          } else {
            final returnType = method.returnType.getDisplayString();
            if (returnType == 'void' || returnType == 'Future<void>') {
              buffer.writeln(
                "      await controller.${method.name}(${argList.join(', ')});",
              );
              buffer.writeln("      return Response.ok(null);");
            } else {
              buffer.writeln(
                "      final result = await controller.${method.name}(${argList.join(', ')});",
              );
              if (returnType == 'Response' ||
                  returnType == 'Future<Response>') {
                buffer.writeln("      return result;");
              } else {
                buffer.writeln(
                  "      return Response.ok(jsonEncode(result), headers: {'content-type': 'application/json'});",
                );
              }
            }
          }
          buffer.writeln("    }); // End of router.register");
        }
      }
    }

    buffer.writeln('}'); // End of factory function

    return buffer.toString();
  }

  /// Helper to get a specific annotation from a parameter
  DartObject? _getAnnotation(
    FormalParameterElement param,
    String annotationName,
  ) {
    for (final meta in param.metadata.annotations) {
      final obj = meta.computeConstantValue();
      final type = obj?.type?.getDisplayString();
      if (type == annotationName) {
        return obj;
      }
    }
    return null;
  }

  String _convertType(
    String expression,
    DartType type, {
    bool isOptional = false,
  }) {
    if (isOptional) {
      // If optional, expression is the 'value' which might be null.
      // "val == null ? null : int.parse(val)"
      if (type.isDartCoreInt)
        return "$expression == null ? null : int.parse($expression)";
      if (type.isDartCoreDouble)
        return "$expression == null ? null : double.parse($expression)";
      if (type.isDartCoreBool) return "$expression == 'true'";
      return expression;
    }

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
