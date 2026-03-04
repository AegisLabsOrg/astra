/// Service lifetime options.
enum ServiceLifetime { singleton, scoped, transient }

/// A descriptor for a registered service.
class ServiceDescriptor<T> {
  final ServiceLifetime lifetime;
  final T Function(Container) factory;

  ServiceDescriptor(this.lifetime, this.factory);
}

/// A simple Dependency Injection Container.
class Container {
  /// The parent container (for scoped containers).
  final Container? _parent;

  /// Service descriptors (inherited from parent if not found).
  final Map<Type, ServiceDescriptor> _descriptors = {};

  /// Instantiated services (cache).
  final Map<Type, Object> _instances = {};

  Container({Container? parent}) : _parent = parent;

  /// Register a dependency instance as a Singleton.
  ///
  /// This is a convenience method for `registerFactory(..., ServiceLifetime.singleton)`.
  void register<T>(Object instance) {
    final descriptor = ServiceDescriptor<T>(
      ServiceLifetime.singleton,
      (_) => instance as T,
    );
    _descriptors[T] = descriptor;
    if (T != instance.runtimeType) {
      _descriptors[instance.runtimeType] = descriptor;
    }
    // Pre-cache it since it's already created
    _instances[T] = instance;
    _instances[instance.runtimeType] = instance;
  }

  /// Register a dynamic factory for a service.
  void registerFactory<T>(
    T Function(Container) factory, {
    ServiceLifetime lifetime = ServiceLifetime.transient,
  }) {
    _registerDescriptor<T>(ServiceDescriptor<T>(lifetime, factory));
  }

  void _registerDescriptor<T>(ServiceDescriptor<T> descriptor) {
    _descriptors[T] = descriptor;
  }

  /// Resolve a dependency
  T resolve<T>() {
    return _resolveType(T) as T;
  }

  Object _resolveType(Type type) {
    // 1. Try to find an existing instance in this container (Scoped/Singleton cache)
    if (_instances.containsKey(type)) {
      return _instances[type]!;
    }

    // 2. Find the descriptor
    final descriptor = _findDescriptor(type);
    if (descriptor == null) {
      throw Exception(
        'Service not found: $type. Did you forget to register it?',
      );
    }

    // 3. Handle based on lifetime
    switch (descriptor.lifetime) {
      case ServiceLifetime.singleton:
        // Singletons must be resolved in the root container
        if (_parent != null) {
          return _parent!._resolveType(type);
        }
        // I am the root, create and cache
        final instance = descriptor.factory(this);
        _instances[type] = instance as Object;
        return instance;

      case ServiceLifetime.scoped:
        // Scoped services are cached in the CURRENT container (which should be a scope)
        // If I am root, I act as a scope too (or maybe fail? No, root scope is fine usually)
        final instance = descriptor.factory(this);
        _instances[type] = instance as Object;
        return instance;

      case ServiceLifetime.transient:
        // Always create new, never cache
        return descriptor.factory(this) as Object;
    }
  }

  ServiceDescriptor? _findDescriptor(Type type) {
    if (_descriptors.containsKey(type)) {
      return _descriptors[type];
    }
    return _parent?._findDescriptor(type);
  }

  /// Creates a new scope (child container) that inherits descriptors.
  Container createScope() {
    return Container(parent: this);
  }
}
