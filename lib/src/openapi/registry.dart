import 'package:astra/src/openapi/models.dart';

class OpenApiRegistry {
  final Map<String, Map<String, OpenApiOperation>> _paths = {};

  final OpenApiInfo info;

  OpenApiRegistry({OpenApiInfo? info})
    : info = info ?? OpenApiInfo(title: 'Astra Application');

  void registerRoute(String method, String path, OpenApiOperation operation) {
    if (!_paths.containsKey(path)) {
      _paths[path] = {};
    }
    _paths[path]![method] = operation;
  }

  OpenApiDocument build() {
    return OpenApiDocument(info: info, paths: _paths);
  }
}
