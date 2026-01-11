import 'route.dart';

/// A simple Radix Trie node for routing.
///
/// Note: This is a simplified implementation.
/// A full production version needs to handle wildcards properly.
class TrieNode {
  final String part;
  // Map of children nodes key by path segment
  final Map<String, TrieNode> children = {};

  // Handlers for this specific path node, keyed by HTTP Method
  final Map<HttpMethod, Function> handlers = {};

  // Is this a parameter node like :id?
  bool isParam = false;
  String paramName = '';

  TrieNode(this.part);
}

class TrieRouter {
  final TrieNode _root = TrieNode('');

  /// Register a route handler
  void register(HttpMethod method, String path, Function handler) {
    // Normalize path: ensure start with / and remove trailing /
    if (!path.startsWith('/')) path = '/$path';
    if (path.length > 1 && path.endsWith('/'))
      path = path.substring(0, path.length - 1);

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    var current = _root;

    for (final segment in segments) {
      if (segment.startsWith(':')) {
        // Parameter node
        // In this simple trie, we assume only one param node per level for simplicity
        // Ideally we check if existing child is param or not
        final paramName = segment.substring(1);

        // Find or create param child
        // For now, let's use a special key for storage, e.g., '?'
        if (!current.children.containsKey('?')) {
          final node = TrieNode('?');
          node.isParam = true;
          node.paramName = paramName;
          current.children['?'] = node;
        }
        current = current.children['?']!;
      } else {
        // Static node
        current = current.children.putIfAbsent(
          segment,
          () => TrieNode(segment),
        );
      }
    }

    current.handlers[method] = handler;
  }

  /// Lookup a route. Returns user handler and parsed params.
  RouteResult? lookup(HttpMethod method, String path) {
    // Normalize path
    if (!path.startsWith('/')) path = '/$path';
    if (path.length > 1 && path.endsWith('/'))
      path = path.substring(0, path.length - 1);

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    var current = _root;
    final Map<String, String> params = {};

    for (final segment in segments) {
      if (current.children.containsKey(segment)) {
        // Exact match
        current = current.children[segment]!;
      } else if (current.children.containsKey('?')) {
        // Param match
        current = current.children['?']!;
        params[current.paramName] = segment;
      } else {
        // No match
        return null;
      }
    }

    final handler = current.handlers[method];
    if (handler == null) return null;

    return RouteResult(handler, params);
  }
}

class RouteResult {
  final Function handler;
  final Map<String, String> pathParams;

  RouteResult(this.handler, this.pathParams);
}
