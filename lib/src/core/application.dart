import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:astra/src/routing/router.dart';
import 'package:astra/src/routing/route.dart';
import 'package:astra/src/di/container.dart';
import 'exceptions.dart';
import 'package:astra/src/openapi/registry.dart';
import 'package:astra/src/openapi/models.dart';

/// The main entry point for an Astra application.
class AstraApp {
  /// The list of controllers registered in the application.
  final List<Object> controllers;

  /// The DI container
  final Container container = Container();

  /// OpenAPI Registry
  final OpenApiRegistry openApiRegistry = OpenApiRegistry();

  /// Internal shelf pipeline
  late Handler _handler;

  /// The router used by the application.
  final TrieRouter router = TrieRouter();

  /// Custom middlewares
  final List<Middleware> middlewares;

  AstraApp({
    this.controllers = const [],
    List<Object> providers = const [],
    this.middlewares = const [],
  }) {
    // Register providers
    for (final provider in providers) {
      // Use runtime type registration.
      // Note: This registers by concrete type.
      // Ideally we would want interface registration, but that requires more complex setup.
      container.register(provider);

      // Also register by runtimeType to be safe for T retrieval
      // Actually Container.register<T> uses T from generic.
      // Calling it dynamically loses T.
      // We need a way to register dynamically.
      // Modifying container to use helper.
    }
    _init();
  }

  void _init() {
    _registerBuiltInRoutes();

    // Basic handler
    var pipeline = Pipeline().addMiddleware(logRequests());

    // Add custom middlewares
    for (final m in middlewares) {
      pipeline = pipeline.addMiddleware(m);
    }

    _handler = pipeline.addHandler(_handleRequest);
  }

  void _registerBuiltInRoutes() {
    router.register(HttpMethod.get, '/openapi.json', (req, params) {
      final doc = openApiRegistry.build();
      return Response.ok(
        jsonEncode(doc.toJson()),
        headers: {'content-type': 'application/json'},
      );
    });

    router.register(HttpMethod.get, '/docs', (req, params) {
      const html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Astra API Docs</title>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700" rel="stylesheet">
    <style>body{margin:0;padding:0;}</style>
</head>
<body>
    <redoc spec-url='/openapi.json'></redoc>
    <script src="https://cdn.jsdelivr.net/npm/redoc@latest/bundles/redoc.standalone.js"></script>
</body>
</html>
''';
      return Response.ok(html, headers: {'content-type': 'text/html'});
    });
  }

  /// Internal request handler that delegates to the router
  Future<Response> _handleRequest(Request request) async {
    // simple mapping from string to HttpMethod
    final method = HttpMethod.values.firstWhere(
      (m) => m.name == request.method,
      orElse: () => HttpMethod.get,
    );

    final result = router.lookup(method, request.url.path);

    if (result == null) {
      return Response.notFound('Not Found');
    }

    try {
      // Pass both request and path params to the handler
      // The generated code must accept (Request request, Map<String, String> pathParams)
      // or handle the dynamic call accordingly.
      // For generated handlers, we will align them to take these 2 args.
      final response = await Function.apply(result.handler, [
        request,
        result.pathParams,
      ]);

      if (response is Response) return response;
      return Response.ok(response.toString());
    } on AstraHttpException catch (e) {
      return Response(e.statusCode, body: e.body ?? e.message);
    } catch (e) {
      return Response.internalServerError(body: 'Internal Error: $e');
    }
  }

  /// Manually register a route (for testing/internal use)
  void get(String path, Function handler) {
    router.register(HttpMethod.get, path, handler);
  }

  /// Starts the HTTP server.
  Future<HttpServer> listen(int port, {String address = '0.0.0.0'}) async {
    final server = await io.serve(_handler, address, port);
    print(
      '🚀 Astra server running on http://${server.address.host}:${server.port}',
    );
    return server;
  }
}
