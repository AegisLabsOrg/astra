import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

class CreateCommand extends Command {
  @override
  final String name = 'create';

  @override
  final String description = 'Creates a new Astra project.';

  final Logger _logger = Logger();

  CreateCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'The output directory for the project.',
    );
  }

  @override
  Future<void> run() async {
    final args = argResults?.rest;
    if (args == null || args.isEmpty) {
      _logger.err(
        'Please specify a project name e.g. "astra create my_project"',
      );
      return;
    }

    final projectName = args.first;
    final outputDir = argResults?['output'] as String? ?? projectName;
    final directory = Directory(outputDir);

    if (await directory.exists()) {
      _logger.err('Directory $outputDir already exists.');
      return;
    }

    _logger.info(
      lightCyan.wrap('🚀 Creating new Astra project: $projectName...'),
    );

    await _createProject(directory, projectName);

    _logger.success('Project created successfully!');
    _logger.info('');
    _logger.info('To get started:');
    _logger.info('  cd $outputDir');
    _logger.info('  dart pub get');
    _logger.info('  dart run build_runner build');
    _logger.info('  dart run bin/server.dart');
  }

  Future<void> _createProject(Directory dir, String projectName) async {
    await dir.create(recursive: true);

    final files = {
      'pubspec.yaml': _pubspec(projectName),
      'analysis_options.yaml': _analysisOptions,
      '.gitignore': _gitignore,
      'README.md': _readme(projectName),
      'Dockerfile': _dockerfile,
      'bin/server.dart': _serverDart(projectName),
      'lib/controllers/home_controller.dart': _homeController(projectName),
    };

    for (final entry in files.entries) {
      final filePath = p.join(dir.path, entry.key);
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsString(entry.value);
    }
  }

  String _pubspec(String name) =>
      '''
name: $name
description: A new Astra project.
version: 1.0.0
publish_to: 'none'

environment:
  sdk: ^3.10.0

dependencies:
  astra: ^0.1.0
  shelf: ^1.4.0
  logging: ^1.2.0

dev_dependencies:
  build_runner: ^2.4.0
  lints: ^2.1.0
  test: ^1.24.0
''';

  String get _analysisOptions => '''
include: package:lints/recommended.yaml

linter:
  rules:
    public_member_api_docs: false
''';

  String get _gitignore => '''
.dart_tool/
.packages
build/
.pub/
.idea/
.vscode/
*.g.dart
pubspec.lock
''';

  String _readme(String name) =>
      '''
# $name

A new Astra project.

## Getting Started

1. Install dependencies:
   ```bash
   dart pub get
   ```

2. Generate code:
   ```bash
   dart run build_runner build
   ```

3. Run the server:
   ```bash
   dart run bin/server.dart
   ```
   
   Or use the dev server with hot reload:
   ```bash
   astra dev -t bin/server.dart
   ```
''';

  String _serverDart(String name) =>
      '''
import 'package:astra_dart/astra.dart';
import 'package:logging/logging.dart';
import 'package:$name/controllers/home_controller.dart';

void main() async {
  // Initialize Logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('\${record.level.name}: \${record.time}: \${record.message}');
  });

  final logger = ConsoleLogger();

  // Initialize App
  final app = AstraApp(
    providers: [],
    middlewares: [requestLogger(logger)],
  );
  app.container.register<AstraLogger>(logger);

  // Register Controllers
  registerHomeController(app);

  // Start Server
  await app.listen(3000);
}
''';

  String _homeController(String name) => '''
import 'package:astra_dart/astra.dart';
import 'package:shelf/shelf.dart';

part 'home_controller.g.dart';

@Controller('/')
class HomeController {
  @Get('/')
  String home() {
    return 'Welcome to Astra!';
  }

  @Get('/ping')
  Map<String, String> ping() {
    return {'message': 'pong'};
  }
}
''';

  String get _dockerfile => '''
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart run build_runner build --delete-conflicting-outputs
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

EXPOSE 3000
CMD ["/app/bin/server"]
''';
}
