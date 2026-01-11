/// A simple Dependency Injection Container.
class Container {
  final Map<Type, Object> _services = {};

  /// Register a dependency instance
  void register<T>(Object instance) {
    _services[instance.runtimeType] = instance;
    if (T != dynamic && T != Object) {
      _services[T] = instance;
    }
  }

  /// Resolve a dependency
  T resolve<T>() {
    // Try explicit T
    if (_services.containsKey(T)) {
      return _services[T] as T;
    }
    // Try finding by iteration (slow, but works for inheritance if we wanted)
    // For now, simple strict matching.
    throw Exception('Service not found: $T. Did you forget to register it?');
  }
}
