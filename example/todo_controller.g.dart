// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_controller.dart';

// **************************************************************************
// ControllerGenerator
// **************************************************************************

extension TodoControllerRoutes on TodoController {
  void registerRoutes(TrieRouter router, OpenApiRegistry openApi) {
    openApi.registerRoute(
      'GET',
      '/todos/',
      OpenApiOperation(operationId: 'getAll'),
    );
    router.register(HttpMethod.get, '/todos/', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final result = await this.getAll();
      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'},
      );
    });
    openApi.registerRoute(
      'POST',
      '/todos/',
      OpenApiOperation(
        operationId: 'create',
        requestBody: {
          'content': {
            'application/json': {
              'schema': {'type': 'object', 'title': 'CreateTodoDto'},
            },
          },
        },
      ),
    );
    router.register(HttpMethod.post, '/todos/', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final bodyBytes_body = await req.readAsString();
      final bodyJson_body = jsonDecode(bodyBytes_body);
      final bodyArg = CreateTodoDto.fromJson(bodyJson_body);
      final result = await this.create(bodyArg);
      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'},
      );
    });
    openApi.registerRoute(
      'GET',
      '/todos/:id',
      OpenApiOperation(
        operationId: 'getById',
        parameters: [
          OpenApiParameter(
            name: 'id',
            location: 'path',
            required: true,
            type: 'string',
          ),
        ],
      ),
    );
    router.register(HttpMethod.get, '/todos/:id', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final result = await this.getById(pathParams['id']!);
      return Response.ok(
        jsonEncode(result),
        headers: {'content-type': 'application/json'},
      );
    });
    openApi.registerRoute(
      'DELETE',
      '/todos/:id',
      OpenApiOperation(
        operationId: 'delete',
        parameters: [
          OpenApiParameter(
            name: 'id',
            location: 'path',
            required: true,
            type: 'string',
          ),
          OpenApiParameter(
            name: 'force',
            location: 'query',
            required: true,
            type: 'boolean',
          ),
        ],
      ),
    );
    router.register(HttpMethod.delete, '/todos/:id', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      await this.delete(
        pathParams['id']!,
        req.url.queryParameters['force']! == 'true',
      );
      return Response.ok(null);
    });
  }
}

void registerTodoController(AstraApp app) {
  final controller = TodoController(
    app.container.resolve<AppDatabase>(),
    app.container.resolve<AstraLogger>(),
  );
  controller.registerRoutes(app.router, app.openApiRegistry);
}
