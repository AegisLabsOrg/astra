import 'package:astra/astra.dart';
import 'package:astra/src/routing/route.dart';
import 'package:shelf/shelf.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

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
