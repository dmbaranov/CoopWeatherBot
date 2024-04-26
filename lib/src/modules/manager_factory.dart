import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'accordion_poll/accordion_poll_manager.dart';
import 'chat/chat_manager.dart';
import 'check_reminder/check_reminder_manager.dart';
import 'command_statistics/command_statistics_manager.dart';
import 'conversator/conversator_manager.dart';
import 'dadjokes/dadjokes_manager.dart';
import 'general/general_manager.dart';
import 'panorama/panorama_manager.dart';
import 'reputation/reputation_manager.dart';
import 'user/user_manager.dart';
import 'weather/weather_manager.dart';
import 'youtube/youtube_manager.dart';
import 'modules_mediator.dart';

class ManagerFactory {
  final Platform platform;
  final ModulesMediator modulesMediator;

  ManagerFactory({required this.platform, required this.modulesMediator});

  final _constructors = <Type, ModuleManager Function(Platform, ModulesMediator)>{
    AccordionPollManager: (platform, modulesMediator) => AccordionPollManager(platform: platform, modulesMediator: modulesMediator),
    ChatManager: (platform, modulesMediator) => ChatManager(platform: platform, modulesMediator: modulesMediator),
    CheckReminderManager: (platform, modulesMediator) => CheckReminderManager(platform: platform, modulesMediator: modulesMediator),
    CommandStatisticsManager: (platform, modulesMediator) => CommandStatisticsManager(platform: platform, modulesMediator: modulesMediator),
    ConversatorManager: (platform, modulesMediator) => ConversatorManager(platform: platform, modulesMediator: modulesMediator),
    DadJokesManager: (platform, modulesMediator) => DadJokesManager(platform: platform, modulesMediator: modulesMediator),
    GeneralManager: (platform, modulesMediator) => GeneralManager(platform: platform, modulesMediator: modulesMediator),
    PanoramaManager: (platform, modulesMediator) => PanoramaManager(platform: platform, modulesMediator: modulesMediator),
    ReputationManager: (platform, modulesMediator) => ReputationManager(platform: platform, modulesMediator: modulesMediator),
    UserManager: (platform, modulesMediator) => UserManager(platform: platform, modulesMediator: modulesMediator),
    WeatherManager: (platform, modulesMediator) => WeatherManager(platform: platform, modulesMediator: modulesMediator),
    YoutubeManager: (platform, modulesMediator) => YoutubeManager(platform: platform, modulesMediator: modulesMediator)
  };

  T createManager<T>() {
    var constructor = _constructors[T];

    if (constructor != null) {
      var instance = constructor(platform, modulesMediator);
      instance.initialize();
      modulesMediator.registerModule(instance.module);
      return instance as T;
    }

    throw Exception('ModuleManager of type $T is not supported');
  }
}
