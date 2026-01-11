import 'package:args/command_runner.dart';
import 'package:astra/src/cli/commands/dev.dart';
import 'package:mason_logger/mason_logger.dart';

class AstraRunner extends CommandRunner<void> {
  final Logger _logger = Logger();

  AstraRunner() : super('astra', 'Astra Framework CLI Tool') {
    addCommand(DevCommand());
  }

  @override
  Future<void> run(Iterable<String> args) async {
    try {
      return await super.run(args);
    } on UsageException catch (e) {
      _logger.err(e.message);
      _logger.info(e.usage);
      // exit(64); // Exit code for usage error
    } catch (e) {
      _logger.err('An error occurred: $e');
    }
  }
}
