import 'accordion_poll/accordion_poll.dart' show AccordionPoll;
import 'chat/chat.dart' show Chat;
import 'check_reminder/check_reminder.dart' show CheckReminder;
import 'command_statistics/command_statistics.dart' show CommandStatistics;
import 'conversator/conversator.dart' show Conversator;
import 'dadjokes/dadjokes.dart' show DadJokes;
import 'general/general.dart' show General;
import 'panorama/panorama.dart' show PanoramaNews;
import 'reputation/reputation.dart' show Reputation;
import 'user/user.dart' show User;
import 'weather/weather.dart' show Weather;
import 'youtube/youtube.dart' show Youtube;

class ModulesMediator {
  late final AccordionPoll accordionPoll;
  late final Chat chat;
  late final CheckReminder checkReminder;
  late final CommandStatistics commandStatistics;
  late final Conversator conversator;
  late final DadJokes dadJokes;
  late final General general;
  late final PanoramaNews panoramaNews;
  late final Reputation reputation;
  late final User user;
  late final Weather weather;
  late final Youtube youtube;

  void registerModule<T>(T moduleInstance) {
    switch (moduleInstance) {
      case AccordionPoll _:
        accordionPoll = moduleInstance;
        break;
      case Chat _:
        chat = moduleInstance;
        break;
      case CheckReminder _:
        checkReminder = moduleInstance;
        break;
      case CommandStatistics _:
        commandStatistics = moduleInstance;
      case Conversator _:
        conversator = moduleInstance;
      case DadJokes _:
        dadJokes = moduleInstance;
      case General _:
        general = moduleInstance;
      case PanoramaNews _:
        panoramaNews = moduleInstance;
      case Reputation _:
        reputation = moduleInstance;
      case User _:
        user = moduleInstance;
        break;
      case Weather _:
        weather = moduleInstance;
        break;
      case Youtube _:
        youtube = moduleInstance;
        break;
      default:
        throw Exception('Unsupported module $moduleInstance');
    }
  }
}
