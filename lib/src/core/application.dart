import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:astra_dart/src/routing/router.dart';
import 'package:astra_dart/src/routing/route.dart';
import 'package:astra_dart/src/di/container.dart';
import 'package:astra_dart/src/modules/logger.dart';
import 'exceptions.dart';
import 'package:astra_dart/src/openapi/registry.dart';

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

    // Create DI scope middleware
    Middleware diScopeMiddleware() {
      return (Handler innerHandler) {
        return (Request request) {
          final scope = container.createScope();
          final context = Map<String, Object>.from(request.context);
          context['astra.container'] = scope;
          return innerHandler(request.change(context: context));
        };
      };
    }

    // Basic handler pipeline
    // Order matters: scope must be available for subsequent middlewares/handlers.
    var pipeline = Pipeline()
        .addMiddleware(diScopeMiddleware())
        .addMiddleware(logRequests());

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

    // Swagger UI (Default Fast API style)
    router.register(HttpMethod.get, '/docs', (req, params) {
      const html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Astra Swagger UI</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui.css" />
</head>
<body>
<div id="swagger-ui"></div>
<script src="https://unpkg.com/swagger-ui-dist@5.9.0/swagger-ui-bundle.js" crossorigin></script>
<script>
  window.onload = () => {
    window.ui = SwaggerUIBundle({
      url: '/openapi.json',
      dom_id: '#swagger-ui',
    });
  };
</script>
</body>
</html>
''';
      return Response.ok(html, headers: {'content-type': 'text/html'});
    });

    // ReDoc
    router.register(HttpMethod.get, '/redoc', (req, params) {
      const html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Astra ReDoc</title>
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
      final response = await Function.apply(result.handler, [
        request,
        result.pathParams,
      ]);

      if (response is Response) return response;
      return Response.ok(response.toString());
    } on AstraHttpException catch (e) {
      final bodyStr = e.body != null ? jsonEncode(e.body) : e.message;
      return Response(
        e.statusCode,
        body: bodyStr,
        headers: {
          'content-type': e.body != null ? 'application/json' : 'text/plain',
        },
      );
    } catch (e, st) {
      print('INTERNAL ERROR: $e\n$st');
      return Response.internalServerError(body: 'Internal Server Error: $e');
    }
  }

  /// Manually register a route (for testing/internal use)
  void get(String path, Function handler) {
    router.register(HttpMethod.get, path, handler);
  }

  /// Starts the HTTP server.
  Future<HttpServer> listen(int port, {String address = '0.0.0.0'}) async {
    final server = await io.serve(_handler, address, port);
    try {
      final logger = container.resolve<AstraLogger>();
      logger.info(
        '🚀 Astra server running on http://${server.address.host}:${server.port}',
      );
    } catch (_) {
      print(
        '🚀 Astra server running on http://${server.address.host}:${server.port}',
      );
    }
    return server;
  }
}
