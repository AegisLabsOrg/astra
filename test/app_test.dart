import 'package:astra/astra.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart'; // Add this import

void main() {
  group('AstraApp Integration Tests', () {
    late AstraApp app;
    final int port = 8081;

    setUp(() async {
      app = AstraApp();
      // Manually register a route for testing
      app.get('/hello', (Request req) {
        return Response.ok('Astra is running! Request to: hello');
      });
      // Start the server in the background
      await app.listen(port);
    });

    // Note: In a real scenario, we need a way to stop the server
    // to release the port for the next test.
    // For now, we'll just test that it starts and responds.

    test('Server responds to GET request with echo', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$port/hello'),
      );

      expect(response.statusCode, equals(200));
      expect(response.body, contains('Astra is running!'));
      expect(response.body, contains('hello'));
    });
  });
}
