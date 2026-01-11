import 'package:shelf/shelf.dart';

/// Context encapsulates the current HTTP request and response building utilities.
class Context {
  final Request request;

  Context(this.request);

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
