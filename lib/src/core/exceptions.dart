/// Base exception class for Astra HTTP errors.
class AstraHttpException implements Exception {
  final int statusCode;
  final String message;
  final dynamic body;

  AstraHttpException(this.statusCode, this.message, {this.body});

  @override
  String toString() => 'AstraHttpException: $message ($statusCode)';
}

/// 400 Bad Request
class BadRequestException extends AstraHttpException {
  BadRequestException(String message, {dynamic body})
    : super(400, message, body: body);
}

/// 401 Unauthorized
class UnauthorizedException extends AstraHttpException {
  UnauthorizedException(String message, {dynamic body})
    : super(401, message, body: body);
}

/// 403 Forbidden
class ForbiddenException extends AstraHttpException {
  ForbiddenException(String message, {dynamic body})
    : super(403, message, body: body);
}

/// 404 Not Found
class NotFoundException extends AstraHttpException {
  NotFoundException(String message, {dynamic body})
    : super(404, message, body: body);
}
