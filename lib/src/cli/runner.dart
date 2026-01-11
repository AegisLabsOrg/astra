import 'package:args/command_runner.dart';
import 'package:astra/src/cli/commands/dev.dart';

class AstraRunner extends CommandRunner<void> {
  AstraRunner() : super('astra', 'Astra Framework CLI Tool') {
    addCommand(DevCommand());
  }

  @override
  Future<void> run(Iterable<String> args) async {
    try {
      return await super.run(args);
    } on UsageException catch (e) {
      print(e);
      // exit(64); // Exit code for usage error
    } catch (e) {
      print('An error occurred: $e');
    }
  }
}
