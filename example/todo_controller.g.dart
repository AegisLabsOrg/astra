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
  app.container.registerFactory<TodoController>(
    (c) => TodoController(c.resolve<AppDatabase>(), c.resolve<AstraLogger>()),
    lifetime: ServiceLifetime.scoped,
  );
  final router = app.router;
  final openApi = app.openApiRegistry;
  openApi.registerRoute(
    'GET',
    '/todos/',
    OpenApiOperation(operationId: 'getAll'),
  );
  router.register(HttpMethod.get, '/todos/', (
    Request req,
    Map<String, String> pathParams,
  ) async {
    final context = Context(req);
    final controller = context.container.resolve<TodoController>();
    final result = await controller.getAll();
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  }); // End of router.register
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
    final context = Context(req);
    final controller = context.container.resolve<TodoController>();
    final bodyBytes_body = await req.readAsString();
    final bodyJson_body = jsonDecode(bodyBytes_body);
    late final CreateTodoDto arg_body;
    try {
      arg_body = CreateTodoDto.fromJson(bodyJson_body);
    } catch (e) {
      throw ValidationException('body', 'Invalid body format: $e');
    }
    final result = await controller.create(arg_body);
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  }); // End of router.register
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
    final context = Context(req);
    final controller = context.container.resolve<TodoController>();
    late final String arg_id;
    try {
      arg_id = pathParams['id']!;
    } catch (e) {
      throw ValidationException('id', 'Invalid format for path parameter: id');
    }
    final result = await controller.getById(arg_id);
    return Response.ok(
      jsonEncode(result),
      headers: {'content-type': 'application/json'},
    );
  }); // End of router.register
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
    final context = Context(req);
    final controller = context.container.resolve<TodoController>();
    late final String arg_id;
    try {
      arg_id = pathParams['id']!;
    } catch (e) {
      throw ValidationException('id', 'Invalid format for path parameter: id');
    }
    late final bool arg_force;
    try {
      arg_force = req.url.queryParameters['force']! == 'true';
    } catch (e) {
      throw ValidationException(
        'force',
        'Invalid format for query parameter: force',
      );
    }
    await controller.delete(arg_id, arg_force);
    return Response.ok(null);
  }); // End of router.register
}
