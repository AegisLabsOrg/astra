import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

class BuildCommand extends Command {
  @override
  final String name = 'build';

  @override
  final String description =
      'Runs the build_runner to generate code, and optionally compiles for production.';

  final Logger _logger = Logger();

  BuildCommand() {
    argParser.addFlag(
      'watch',
      abbr: 'w',
      help: 'Watch for changes and rebuild automatically.',
      negatable: false,
    );
    argParser.addFlag(
      'clean',
      help: 'Clean the build outputs before building.',
      negatable: false,
    );
    argParser.addFlag(
      'production',
      abbr: 'p',
      help: 'Creates a production build (AOT compiled executable).',
      negatable: false,
    );
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'The specific Dart entry point to compile.',
      defaultsTo: 'bin/server.dart',
    );
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'The output path for the executable.',
      defaultsTo: 'build/bin/server',
    );
  }

  @override
  Future<void> run() async {
    final isWatch = argResults?['watch'] as bool;
    final isClean = argResults?['clean'] as bool;
    final isProduction = argResults?['production'] as bool;
    final target = argResults?['target'] as String;
    final output = argResults?['output'] as String;

    if (isWatch && isProduction) {
      _logger.err('Cannot use --watch and --production together.');
      return;
    }

    _logger.info(lightCyan.wrap('🔨 Running build_runner...')!);

    final args = ['run', 'build_runner'];

    if (isWatch) {
      args.add('watch');
    } else {
      args.add('build');
    }

    args.add('--delete-conflicting-outputs');

    if (isClean) {
      await Process.run('dart', ['run', 'build_runner', 'clean']);
    }

    final buildProcess = await Process.start(
      'dart',
      args,
      mode: ProcessStartMode.inheritStdio,
    );

    final buildExitCode = await buildProcess.exitCode;

    if (buildExitCode != 0) {
      _logger.err('Build failed with exit code $buildExitCode');
      return;
    }

    if (isProduction) {
      if (!File(target).existsSync()) {
        // Try fallback to example/server.dart if bin/server.dart missing (for demo purposes)
        if (target == 'bin/server.dart' &&
            File('example/server.dart').existsSync()) {
          _createProductionBuild('example/server.dart', output);
          return;
        }
        _logger.err('Target file not found: $target');
        return;
      }
      await _createProductionBuild(target, output);
    } else {
      _logger.success('Build completed successfully!');
    }
  }

  Future<void> _createProductionBuild(String target, String output) async {
    _logger.info(lightCyan.wrap('🚀 Compiling native executable...')!);

    // Ensure output directory exists
    final outputDir = File(output).parent;
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final compileArgs = ['compile', 'exe', target, '-o', output];

    final compileProcess = await Process.start(
      'dart',
      compileArgs,
      mode: ProcessStartMode.inheritStdio,
    );

    final compileExitCode = await compileProcess.exitCode;

    if (compileExitCode == 0) {
      _logger.success('✅ Production build created at $output');
      _logger.info('Run with: ./$output');
    } else {
      _logger.err('Compilation failed with exit code $compileExitCode');
    }
  }
}
