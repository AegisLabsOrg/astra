/// Abstract Interface for Caching
abstract class CacheManager {
  Future<void> set(String key, dynamic value, {Duration? ttl});
  Future<dynamic> get(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

/// Abstract Interface for Database Connection
abstract class DatabaseConnection {
  Future<void> connect();
  Future<void> disconnect();
  Future<T> transaction<T>(Future<T> Function(dynamic txn) action);
}

/// InMemory Cache Implementation (Default)
class InMemoryCache implements CacheManager {
  final Map<String, _CacheItem> _store = {};

  @override
  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    final expiry = ttl != null ? DateTime.now().add(ttl) : null;
    _store[key] = _CacheItem(value, expiry);
  }

  @override
  Future<dynamic> get(String key) async {
    final item = _store[key];
    if (item == null) return null;
    if (item.isExpired) {
      _store.remove(key);
      return null;
    }
    return item.value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

class _CacheItem {
  final dynamic value;
  final DateTime? expiry;
  _CacheItem(this.value, this.expiry);
  bool get isExpired => expiry != null && DateTime.now().isAfter(expiry!);
}
