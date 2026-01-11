/// Base class for HTTP methods
abstract class HttpMethodAnnotation {
  final String path;
  const HttpMethodAnnotation(this.path);
}

/// Annotation for HTTP GET requests
class Get extends HttpMethodAnnotation {
  const Get(String path) : super(path);
}

/// Annotation for HTTP POST requests
class Post extends HttpMethodAnnotation {
  const Post(String path) : super(path);
}

/// Annotation for HTTP PUT requests
class Put extends HttpMethodAnnotation {
  const Put(String path) : super(path);
}

/// Annotation for HTTP DELETE requests
class Delete extends HttpMethodAnnotation {
  const Delete(String path) : super(path);
}

/// Annotation for HTTP PATCH requests
class Patch extends HttpMethodAnnotation {
  const Patch(String path) : super(path);
}

/// Annotation for WebSocket routes
class WebSocketRoute extends HttpMethodAnnotation {
  const WebSocketRoute(String path) : super(path);
}

/// Annotation for Controllers
class Controller {
  final String path;
  const Controller(this.path);
}

/// Annotation for Path Parameters
class Path {
  final String? name;
  const Path([this.name]);
}

/// Annotation for Query Parameters
class Query {
  final String? name;
  const Query([this.name]);
}

/// Annotation for Request Body
class Body {
  const Body();
}
