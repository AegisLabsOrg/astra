// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sample_controller.dart';

// **************************************************************************
// ControllerGenerator
// **************************************************************************

extension UserControllerRoutes on UserController {
  void registerRoutes(TrieRouter router, OpenApiRegistry openApi) {
    openApi.registerRoute(
      'GET',
      '/users/',
      OpenApiOperation(operationId: 'getAll'),
    );
    router.register(HttpMethod.get, '/users/', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final result = await this.getAll();
      return result;
    });
    openApi.registerRoute(
      'GET',
      '/users/me',
      OpenApiOperation(operationId: 'getProfile'),
    );
    router.register(HttpMethod.get, '/users/me', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final result = await this.getProfile(req);
      return result;
    });
    openApi.registerRoute(
      'POST',
      '/users/create',
      OpenApiOperation(
        operationId: 'create',
        requestBody: {
          'content': {
            'application/json': {
              'schema': {'type': 'object', 'title': 'CreateUserDto'},
            },
          },
        },
      ),
    );
    router.register(HttpMethod.post, '/users/create', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final bodyBytes_body = await req.readAsString();
      final bodyJson_body = jsonDecode(bodyBytes_body);
      final bodyArg = CreateUserDto.fromJson(bodyJson_body);
      final result = await this.create(bodyArg);
      return result;
    });
    openApi.registerRoute(
      'GET',
      '/users/:id',
      OpenApiOperation(
        operationId: 'getById',
        parameters: [
          OpenApiParameter(
            name: 'id',
            location: 'path',
            required: true,
            type: 'integer',
          ),
          OpenApiParameter(
            name: 'details',
            location: 'query',
            required: true,
            type: 'string',
          ),
        ],
      ),
    );
    router.register(HttpMethod.get, '/users/:id', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final result = await this.getById(
        int.parse(pathParams['id']!),
        req.url.queryParameters['details']!,
      );
      return result;
    });
    openApi.registerRoute(
      'GET',
      '/users/dto',
      OpenApiOperation(operationId: 'getDto'),
    );
    router.register(HttpMethod.get, '/users/dto', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final result = await this.getDto();
      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'},
      );
    });
    openApi.registerRoute(
      'GET',
      '/users/error',
      OpenApiOperation(operationId: 'throwError'),
    );
    router.register(HttpMethod.get, '/users/error', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      await this.throwError();
      return Response.ok(null);
    });
  }
}

void registerUserController(AstraApp app) {
  final controller = UserController(
    app.container.resolve<UserService>(),
    app.container.resolve<AstraLogger>(),
  );
  controller.registerRoutes(app.router, app.openApiRegistry);
}
