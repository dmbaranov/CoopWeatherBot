import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/platform/platform.dart';
import 'modules_mediator.dart';

import 'dadjokes/dadjokes_manager.dart';
import 'youtube/youtube_manager.dart';
import 'conversator/conversator_manager.dart';
import 'general/general_manager.dart';
import 'chat/chat_manager.dart';
import 'panorama/panorama_manager.dart';
import 'user/user_manager.dart';
import 'reputation/reputation_manager.dart';
import 'weather/weather_manager.dart';
import 'accordion_poll/accordion_poll_manager.dart';
import 'command_statistics/command_statistics_manager.dart';
import 'check_reminder/check_reminder_manager.dart';

typedef ManagerBuilder = ModuleManager Function(Platform platform, ModulesMediator modulesMediator);

final List<ManagerBuilder> modules = [
  (p, m) => DadJokesManager(p, m),
  (p, m) => YoutubeManager(p, m),
  (p, m) => ConversatorManager(p, m),
  (p, m) => GeneralManager(p, m),
  (p, m) => ChatManager(p, m),
  (p, m) => PanoramaManager(p, m),
  (p, m) => UserManager(p, m),
  (p, m) => ReputationManager(p, m),
  (p, m) => WeatherManager(p, m),
  (p, m) => AccordionPollManager(p, m),
  (p, m) => CommandStatisticsManager(p, m),
  (p, m) => CheckReminderManager(p, m),
];

void initializeModules({required Platform platform, required ModulesMediator modulesMediator}) {
  modules.forEach((builder) {
    var manager = builder(platform, modulesMediator)
      ..initialize()
      ..setupCommands();

    var module = manager.module;
    if (module != null) {
      modulesMediator.registerModule(module);
    }
  });
}
