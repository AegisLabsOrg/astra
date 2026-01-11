/// Astra Framework
///
/// A modern, type-safe web framework for Dart inspired by FastAPI.
library astra;

// Core
export 'src/core/application.dart';
export 'src/core/exceptions.dart';
export 'src/http/context.dart';

// OpenApi
export 'src/openapi/models.dart';
export 'src/openapi/registry.dart';

// Modules (Standard Library)
export 'src/modules/auth.dart';
export 'src/modules/logger.dart';
export 'src/modules/persistence.dart';
// WebSocket support
export 'package:shelf_web_socket/shelf_web_socket.dart';
export 'package:web_socket_channel/web_socket_channel.dart';

// Meta (Annotations)
export 'src/meta/annotations.dart';

export 'src/routing/router.dart';
export 'package:shelf/shelf.dart' show Request, Response, Handler;

// DI
export 'src/di/container.dart';

// HTTP
// export 'src/http/response.dart';

// Macros (Annotations)
// export 'src/macros/controller.dart';
// export 'src/macros/http_methods.dart';
