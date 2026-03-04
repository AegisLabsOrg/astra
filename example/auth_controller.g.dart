// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// ControllerGenerator
// **************************************************************************

extension AuthControllerRoutes on AuthController {
  void registerRoutes(TrieRouter router, OpenApiRegistry openApi) {
    openApi.registerRoute(
      'POST',
      '/auth/login',
      OpenApiOperation(
        operationId: 'login',
        requestBody: {
          'content': {
            'application/json': {
              'schema': {'type': 'object', 'title': 'LoginDto'},
            },
          },
        },
      ),
    );
    router.register(HttpMethod.post, '/auth/login', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final bodyBytes_body = await req.readAsString();
      final bodyJson_body = jsonDecode(bodyBytes_body);
      final bodyArg = LoginDto.fromJson(bodyJson_body);
      final result = await this.login(bodyArg);
      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'},
      );
    });
    openApi.registerRoute(
      'GET',
      '/auth/me',
      OpenApiOperation(operationId: 'me'),
    );
    router.register(HttpMethod.get, '/auth/me', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final result = await this.me(req);
      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'},
      );
    });
  }
}

void registerAuthController(AstraApp app) {
  app.container.registerFactory<AuthController>(
    (c) => AuthController(c.resolve<AuthService>()),
    lifetime: ServiceLifetime.scoped,
  );
  final router = app.router;
  final openApi = app.openApiRegistry;
  openApi.registerRoute(
    'POST',
    '/auth/login',
    OpenApiOperation(
      operationId: 'login',
      requestBody: {
        'content': {
          'application/json': {
            'schema': {'type': 'object', 'title': 'LoginDto'},
          },
        },
      },
    ),
  );
  router.register(HttpMethod.post, '/auth/login', (
    Request req,
    Map<String, String> pathParams,
  ) async {
    final context = Context(req);
    final controller = context.container.resolve<AuthController>();
    final bodyBytes_body = await req.readAsString();
    final bodyJson_body = jsonDecode(bodyBytes_body);
    late final LoginDto arg_body;
    try {
      arg_body = LoginDto.fromJson(bodyJson_body);
    } catch (e) {
      throw ValidationException('body', 'Invalid body format: $e');
    }
    final result = await controller.login(arg_body);
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  }); // End of router.register
  openApi.registerRoute('GET', '/auth/me', OpenApiOperation(operationId: 'me'));
  router.register(HttpMethod.get, '/auth/me', (
    Request req,
    Map<String, String> pathParams,
  ) async {
    final context = Context(req);
    final controller = context.container.resolve<AuthController>();
    final result = await controller.me(req);
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  }); // End of router.register
}
