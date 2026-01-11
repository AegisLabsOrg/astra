import 'dart:io';
import 'package:astra/astra.dart';
import 'package:astra/src/sample_controller.dart';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart'; // Add this import
import 'package:http/http.dart' as http;

void main() {
  group('Generated Routes Integration', () {
    late AstraApp app;
    late HttpServer server;
    // final int port = 8082;
    late int port;

    setUp(() async {
      // Services
      final logger = ConsoleLogger();
      final authService = SimpleAuthService('secret');

      // 1. Setup App & DI with Middleware
      app = AstraApp(
        providers: [UserService()],
        middlewares: [
          requestLogger(logger),
          authMiddleware(authService, optional: true),
          (innerHandler) => (request) async {
            final response = await innerHandler(request);
            return response.change(headers: {'X-Test-Middleware': 'true'});
          },
        ],
      );

      // Manual Registration for Interfaces
      app.container.register<AstraLogger>(logger);
      app.container.register<AuthService>(authService);

      // 2. Register Controller using the Generated Factory
      // The old way: final userController = UserController(); (Error: missing arg)
      // The new Astra way:
      registerUserController(app);
      server = await app.listen(0);
      port = server.port;
    });
    test('GET /users/ calls getAll (0 args wrapped)', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$port/users/'),
      );
      expect(response.statusCode, 200);
      expect(response.body, 'Hello service user: Guest');
    });

    test('POST /users/create calls create with parsed JSON Body', () async {
      final response = await http.post(
        Uri.parse('http://localhost:$port/users/create'),
        body: '{"name": "Alice", "email": "alice@example.com"}',
      );
      expect(response.statusCode, 200);
      expect(response.body, 'Created user: Alice');
    });

    test(
      'GET /users/123?details=full calls getById (Path & Query params)',
      () async {
        final response = await http.get(
          Uri.parse('http://localhost:$port/users/123?details=full'),
        );
        expect(response.statusCode, 200);
        expect(response.body, 'User: 123, details: full');
      },
    );

    test('GET /users/dto returns JSON (Smart Return)', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$port/users/dto'),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('application/json'));
      expect(response.body, contains('auto@example.com'));
    });

    test('GET /users/error returns 400 (Global Exception Handling)', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$port/users/error'),
      );
      expect(response.statusCode, 400);
      expect(response.body, 'Simulated Error');
    });

    test('Middleware adds custom header', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$port/users/'),
      );
      expect(response.headers['x-test-middleware'], 'true');
    });

    test('GET /openapi.json returns Valid Spec', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$port/openapi.json'),
      );
      expect(response.statusCode, 200);
      expect(response.body, contains('"openapi":"3.0.0"'));
      expect(response.body, contains('"/users/create"'));
      expect(response.body, contains('"operationId":"getById"'));
    });

    test('GET /docs returns HTML', () async {
      final response = await http.get(Uri.parse('http://localhost:$port/docs'));
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], contains('text/html'));
      expect(
        response.body,
        contains('<redoc spec-url=\'/openapi.json\'></redoc>'),
      );
    });

    test('GET /users/me returns 401 without token', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$port/users/me'),
      );
      // We expect 401 because User is null, and controller checks it.
      // Wait, middleware is optional=true, so context['user'] is null.
      // Controller throws UnauthorizedException. Global Handler catches.
      // UnauthorizedException maps to 401.
      expect(response.statusCode, 401);
    });

    test('GET /users/me returns Profile with token', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$port/users/me'),
        headers: {'Authorization': 'Bearer valid_token_123'},
      );
      expect(response.statusCode, 200);
      expect(response.body, contains('User123'));
    });
  });
}
