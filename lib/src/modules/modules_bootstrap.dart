import 'package:weather/src/platform/platform.dart';
import 'manager_factory.dart';
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

class ModulesBootstrap {
  final Platform platform;
  final ModulesMediator modulesMediator;

  ModulesBootstrap({required this.platform, required this.modulesMediator});

  void initialize() {
    var managerFactory = ManagerFactory(platform: platform, modulesMediator: modulesMediator);

    managerFactory.createManager<DadJokesManager>();
    managerFactory.createManager<YoutubeManager>();
    managerFactory.createManager<ConversatorManager>();
    managerFactory.createManager<GeneralManager>();
    managerFactory.createManager<ChatManager>();
    managerFactory.createManager<PanoramaManager>();
    managerFactory.createManager<UserManager>();
    managerFactory.createManager<ReputationManager>();
    managerFactory.createManager<WeatherManager>();
    managerFactory.createManager<AccordionPollManager>();
    managerFactory.createManager<CommandStatisticsManager>();
    managerFactory.createManager<CheckReminderManager>();
  }
}
