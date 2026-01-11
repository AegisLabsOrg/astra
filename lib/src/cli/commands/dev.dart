import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:watcher/watcher.dart';

class DevCommand extends Command {
  @override
  final String name = 'dev';

  @override
  final String description = 'Starts the development server with hot reload.';

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
      print('❌ Target file not found: $target');
      print('   Please create $target or specify a file with --target');
      return;
    }

    print('🔧 Starting Astra development server...');
    print('   Target: $target');
    print('   Watching: lib/**, bin/**');

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

    print('🚀 (Re)starting server...');
    try {
      _process = await Process.start('dart', [
        'run',
        target,
      ], mode: ProcessStartMode.inheritStdio);

      // We don't await exit code here because the server is long-running
    } catch (e) {
      print('❌ Failed to start server: $e');
    }
  }

  void _stopServer() {
    _process?.kill();
    _subscription?.cancel();
    print('\n👋 Server stopped.');
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

      print('🔄 Change detected: ${event.path}');
      await _startServer(target);
      _isReloading = false;
    });
  }
}
