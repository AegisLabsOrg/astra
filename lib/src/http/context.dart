import 'package:shelf/shelf.dart';
import 'package:astra_dart/src/di/container.dart';

/// Context encapsulates the current HTTP request and response building utilities.
class Context {
  final Request request;
  late final Container container;

  Context(this.request) {
    // Try to get container from request context
    final scope = request.context['astra.container'];
    if (scope is Container) {
      container = scope;
    } else {
      // Fallback or throw? Ideally application logic handles this.
      // For now, create an empty one or throw.
      // But Context constructed by user... wait, usually framework constructs it.
      // If manually constructed, it might fail.
      throw StateError(
        'Context created without a DI container in request context.',
      );
    }
  }

  /// Returns a JSON response.
  Response json(
    Object? body, {
    int statusCode = 200,
    Map<String, Object>? headers,
  }) {
    // TODO: Implement JSON serialization
    return Response(
      statusCode,
      body: body.toString(),
      headers: {'content-type': 'application/json', ...?headers},
    );
  }

  /// Returns a text response.
  Response text(
    String body, {
    int statusCode = 200,
    Map<String, Object>? headers,
  }) {
    return Response(
      statusCode,
      body: body,
      headers: {'content-type': 'text/plain', ...?headers},
    );
  }
}
