import 'dart:mirrors';

import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'modules_mediator.dart';

class ManagerFactory {
  final Platform platform;
  final ModulesMediator modulesMediator;

  ManagerFactory({required this.platform, required this.modulesMediator});

  T createManager<T extends ModuleManager>() {
    T instance = reflectClass(T).newInstance(Symbol(''), [platform, modulesMediator]).reflectee;

    instance.initialize();
    instance.setupCommands();
    modulesMediator.registerModule(instance.module);

    return instance;
  }
}
