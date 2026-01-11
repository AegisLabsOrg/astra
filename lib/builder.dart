import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/generator/controller_generator.dart';

Builder controllerBuilder(BuilderOptions options) =>
    SharedPartBuilder([ControllerGenerator()], 'astra_controller');
