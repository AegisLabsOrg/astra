import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

class MakeCommand extends Command {
  @override
  final String name = 'make';

  @override
  final String description =
      'Generates new code elements (controllers, services, etc).';

  MakeCommand() {
    addSubcommand(MakeControllerCommand());
    addSubcommand(MakeServiceCommand());
  }
}

class MakeControllerCommand extends Command {
  @override
  final String name = 'controller';

  @override
  final String description = 'Generates a new controller.';

  final Logger _logger = Logger();

  MakeControllerCommand() {
    argParser.addOption(
      'path',
      abbr: 'p',
      help:
          'The URL path for the controller (e.g. /users). Defaults to the name.',
    );
  }

  @override
  Future<void> run() async {
    final args = argResults?.rest;
    if (args == null || args.isEmpty) {
      _logger.err(
        'Please specify a controller name e.g. "astra make controller User"',
      );
      return;
    }

    final rawName = args.first;
    // Normalize name: User -> user, UserController -> user
    var baseName = rawName.toLowerCase();
    if (baseName.endsWith('controller')) {
      baseName = baseName.substring(0, baseName.length - 10);
    }

    // PascalCase for class name
    final className =
        '${baseName[0].toUpperCase()}${baseName.substring(1)}Controller';
    // snake_case for file name
    final fileName = '${baseName}_controller.dart';

    final pathOption = argResults?['path'] as String?;
    final urlPath = pathOption ?? '/$baseName';

    final content =
        '''
import 'package:astra_dart/astra.dart';
import 'package:shelf/shelf.dart';

part '$fileName.g.dart'; // Ensure generation works

@Controller('$urlPath')
class $className {
  
  $className();

  @Get('/')
  Future<String> index() async {
    return 'Hello from $className';
  }

  @Get('/:id')
  Future<String> findOne(@Path() String id) async {
    return 'Get $baseName \$id';
  }
}
''';

    // Assume standard structure: lib/src/controllers/ or lib/controllers/
    // We'll try to put it in lib/controllers if it exists, otherwise lib/src/controllers if exists, otherwise lib/
    var targetDir = Directory('lib/controllers');
    if (!targetDir.existsSync()) {
      final srcDir = Directory('lib/src/controllers');
      if (srcDir.existsSync()) {
        targetDir = srcDir;
      } else {
        // Fallback or create default
        targetDir.createSync(recursive: true);
      }
    }

    final filePath = p.join(targetDir.path, fileName);
    final file = File(filePath);

    if (await file.exists()) {
      _logger.err('File $filePath already exists.');
      return;
    }

    await file.writeAsString(content);
    _logger.success('Created controller: $filePath');
    _logger.info('Don\'t forget to register it in your main app file!');
  }
}

class MakeServiceCommand extends Command {
  @override
  final String name = 'service';

  @override
  final String description = 'Generates a new service.';

  final Logger _logger = Logger();

  @override
  Future<void> run() async {
    final args = argResults?.rest;
    if (args == null || args.isEmpty) {
      _logger.err(
        'Please specify a service name e.g. "astra make service User"',
      );
      return;
    }

    final rawName = args.first;
    var baseName = rawName.toLowerCase();

    // PascalCase
    final className =
        '${baseName[0].toUpperCase()}${baseName.substring(1)}Service';
    // snake_case
    final fileName = '${baseName}_service.dart';

    final content =
        '''
class $className {
  // Add dependency injection if needed
  // final Database db;
  // $className(this.db);
  
  Future<void> doSomething() async {
    // Business logic...
  }
}
''';

    var targetDir = Directory('lib/services');
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final filePath = p.join(targetDir.path, fileName);
    final file = File(filePath);

    if (await file.exists()) {
      _logger.err('File $filePath already exists.');
      return;
    }

    await file.writeAsString(content);
    _logger.success('Created service: $filePath');
  }
}
