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
  final controller = WebSocketController(app.container.resolve<AstraLogger>());
  controller.registerRoutes(app.router, app.openApiRegistry);
}
