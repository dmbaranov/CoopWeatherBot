import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/bootstrap.dart';
import 'package:weather/src/modules/modules_mediator.dart';

class Bot {
  final Config _config;

  Bot() : _config = getIt<Config>();

  Future<void> startBot() async {
    var modulesMediator = ModulesMediator();
    var platform = Platform(chatPlatform: _config.chatPlatform, modulesMediator: modulesMediator)..initialize();

    initializeModules(platform: platform, modulesMediator: modulesMediator);
    await platform.postStart();
  }
}
