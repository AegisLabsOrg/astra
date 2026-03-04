import 'package:astra_dart/astra.dart';
import 'package:astra_dart/src/routing/route.dart';

part 'websocket_controller.g.dart';

@Controller('/ws')
class WebSocketController {
  final AstraLogger logger;

  WebSocketController(this.logger);

  // A simple echo WebSocket
  @WebSocketRoute('/echo')
  void echo(WebSocketChannel channel) {
    logger.info('New WebSocket connection to /ws/echo');
    channel.stream.listen(
      (message) {
        logger.info('Received: $message');
        channel.sink.add('Echo: $message');
      },
      onDone: () {
        logger.info('WebSocket closed');
      },
    );
  }

  // A room-based chat (simplified)
  @WebSocketRoute('/chat/:room')
  void chat(WebSocketChannel channel, @Path() String room) {
    logger.info('Joined room: $room');
    channel.sink.add('Welcome to room $room');

    channel.stream.listen((message) {
      channel.sink.add('You said: "$message" in room $room');
    });
  }
}
