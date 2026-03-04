// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_controller.dart';

// **************************************************************************
// ControllerGenerator
// **************************************************************************

extension WebSocketControllerRoutes on WebSocketController {
  void registerRoutes(TrieRouter router, OpenApiRegistry openApi) {
    openApi.registerRoute(
      'GET',
      '/ws/echo',
      OpenApiOperation(operationId: 'echo'),
    );
    router.register(HttpMethod.get, '/ws/echo', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final wsHandler = webSocketHandler((
        WebSocketChannel wsChannel,
        String? protocol,
      ) {
        this.echo(wsChannel);
      });
      return wsHandler(req);
    });
    openApi.registerRoute(
      'GET',
      '/ws/chat/:room',
      OpenApiOperation(
        operationId: 'chat',
        parameters: [
          OpenApiParameter(
            name: 'room',
            location: 'path',
            required: true,
            type: 'string',
          ),
        ],
      ),
    );
    router.register(HttpMethod.get, '/ws/chat/:room', (
      Request req,
      Map<String, String> pathParams,
    ) async {
      final wsHandler = webSocketHandler((
        WebSocketChannel wsChannel,
        String? protocol,
      ) {
        this.chat(wsChannel, pathParams['room']!);
      });
      return wsHandler(req);
    });
  }
}

void registerWebSocketController(AstraApp app) {
  app.container.registerFactory<WebSocketController>(
    (c) => WebSocketController(c.resolve<AstraLogger>()),
    lifetime: ServiceLifetime.scoped,
  );
  final router = app.router;
  final openApi = app.openApiRegistry;
  openApi.registerRoute(
    'GET',
    '/ws/echo',
    OpenApiOperation(operationId: 'echo'),
  );
  router.register(HttpMethod.get, '/ws/echo', (
    Request req,
    Map<String, String> pathParams,
  ) async {
    final context = Context(req);
    final controller = context.container.resolve<WebSocketController>();
    final wsHandler = webSocketHandler((
      WebSocketChannel wsChannel,
      String? protocol,
    ) {
      controller.echo(wsChannel);
    });
    return wsHandler(req);
  }); // End of router.register
  openApi.registerRoute(
    'GET',
    '/ws/chat/:room',
    OpenApiOperation(
      operationId: 'chat',
      parameters: [
        OpenApiParameter(
          name: 'room',
          location: 'path',
          required: true,
          type: 'string',
        ),
      ],
    ),
  );
  router.register(HttpMethod.get, '/ws/chat/:room', (
    Request req,
    Map<String, String> pathParams,
  ) async {
    final context = Context(req);
    final controller = context.container.resolve<WebSocketController>();
    final wsHandler = webSocketHandler((
      WebSocketChannel wsChannel,
      String? protocol,
    ) {
      late final String arg_room;
      try {
        arg_room = pathParams['room']!;
      } catch (e) {
        throw ValidationException(
          'room',
          'Invalid format for path parameter: room',
        );
      }
      controller.chat(wsChannel, arg_room);
    });
    return wsHandler(req);
  }); // End of router.register
}
