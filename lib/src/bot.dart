import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/modules_bootstrap.dart';
import 'package:weather/src/modules/modules_mediator.dart';

class Bot {
  final Config _config;

  Bot() : _config = getIt<Config>();

  Future<void> startBot() async {
    var modulesMediator = ModulesMediator();
    var platform = Platform(chatPlatform: _config.chatPlatform, modulesMediator: modulesMediator)..initialize();
    ModulesBootstrap(platform: platform, modulesMediator: modulesMediator).initialize();

    await platform.postStart();
  }
}
