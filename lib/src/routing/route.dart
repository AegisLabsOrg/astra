/// HTTP Methods supported by Astra
enum HttpMethod {
  get,
  post,
  put,
  delete,
  patch,
  head,
  options;

  String get name => toString().split('.').last.toUpperCase();
}

/// Represents a registered route entry
class RouteEntry {
  final HttpMethod method;
  final String path;
  final Function handler; // We will refine this type later

  const RouteEntry(this.method, this.path, this.handler);
}
