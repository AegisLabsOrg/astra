import 'dart:io';
import 'package:shelf/shelf.dart';

/// Abstract Logger Interface
abstract class AstraLogger {
  void info(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);
  void warning(String message);
  void debug(String message);
}

/// Default Console Logger
class ConsoleLogger implements AstraLogger {
  @override
  void info(String message) => print('INFO: $message');

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      print('ERROR: $message ${error ?? ""}');

  @override
  void warning(String message) => print('WARN: $message');

  @override
  void debug(String message) => print('DEBUG: $message');
}

/// Simple File Logger
class FileLogger implements AstraLogger {
  final File file;

  FileLogger(String path) : file = File(path);

  void _log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    final line = '$timestamp [$level] $message\n';
    file.writeAsStringSync(line, mode: FileMode.append);
  }

  @override
  void info(String message) => _log('INFO', message);

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log('ERROR', '$message ${error ?? ""}');

  @override
  void warning(String message) => _log('WARN', message);

  @override
  void debug(String message) => _log('DEBUG', message);
}

/// Middleware that logs requests using the provided [logger].
Middleware requestLogger(AstraLogger logger) {
  return (Handler innerHandler) {
    return (Request request) async {
      final startTime = DateTime.now();

      try {
        final response = await innerHandler(request);
        final duration = DateTime.now().difference(startTime);
        logger.info(
          '${request.method} ${request.url.path} [${response.statusCode}] (${duration.inMilliseconds}ms)',
        );
        return response;
      } catch (error, stackTrace) {
        final duration = DateTime.now().difference(startTime);
        logger.error(
          '${request.method} ${request.url.path} [ERROR] (${duration.inMilliseconds}ms)',
          error,
          stackTrace,
        );
        rethrow;
      }
    };
  };
}
