import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/modules_mediator.dart';

abstract class ModuleManager<T extends Object> {
  final Platform platform;
  final ModulesMediator modulesMediator;

  ModuleManager(this.platform, this.modulesMediator);

  T? get module;

  void initialize();

  void setupCommands();
}
