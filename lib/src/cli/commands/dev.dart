import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:watcher/watcher.dart';
import 'package:mason_logger/mason_logger.dart';

class DevCommand extends Command {
  @override
  final String name = 'dev';

  @override
  final String description = 'Starts the development server with hot reload.';

  final Logger _logger = Logger();

  Process? _process;
  StreamSubscription? _subscription;
  bool _isReloading = false;

  DevCommand() {
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'The specific Dart entry point to run.',
      defaultsTo: 'bin/main.dart',
    );
  }

  @override
  Future<void> run() async {
    final target = argResults?['target'] as String;

    if (!File(target).existsSync()) {
      _logger.err('Target file not found: $target');
      _logger.detail('Please create $target or specify a file with --target');
      return;
    }

    _logger.info(backgroundBlue.wrap(white.wrap(' Astra Dev Server '))!);
    _logger.info(styleBold.wrap('Target: ')! + target);
    _logger.info(styleDim.wrap('Watching: lib/**, bin/**'));

    await _startServer(target);
    _watch(target);

    // Keep the command running
    final completer = Completer<void>();
    ProcessSignal.sigint.watch().listen((_) {
      _stopServer();
      completer.complete();
    });
    await completer.future;
  }

  Future<void> _startServer(String target) async {
    if (_process != null) {
      _process!.kill();
    }

    _logger.info(lightCyan.wrap('🚀 (Re)starting server...'));
    try {
      _process = await Process.start('dart', [
        'run',
        target,
      ], mode: ProcessStartMode.inheritStdio);

      // We don't await exit code here because the server is long-running
    } catch (e) {
      _logger.err('Failed to start server: $e');
    }
  }

  void _stopServer() {
    _process?.kill();
    _subscription?.cancel();
    _logger.info('\n👋 Server stopped.');
  }

  void _watch(String target) {
    // Watch current directory (or specifically lib/ and bin/)
    // For simplicity, watching current dir but filtering for .dart files
    final watcher = DirectoryWatcher(Directory.current.path);

    _subscription = watcher.events.listen((event) async {
      if (!event.path.endsWith('.dart')) return;
      if (_isReloading) return;

      _isReloading = true;
      // Simple debounce
      await Future.delayed(Duration(milliseconds: 200));

      _logger.info(darkGray.wrap('🔄 Change detected: ${event.path}'));
      await _startServer(target);
      _isReloading = false;
    });
  }
}
