import 'package:postgres/postgres.dart';

import 'repositories/bot_user_repository.dart';
import 'repositories/chat_repository.dart';
import 'repositories/reputation_repository.dart';
import 'repositories/weather_repository.dart';
import 'repositories/news_repository.dart';
import 'repositories/conversator_chat_repository.dart';
import 'repositories/conversator_user_repository.dart';
import 'repositories/command_statistics_repository.dart';
import 'repositories/check_reminder_repository.dart';

class Database {
  final Pool dbConnection;
  final BotUserRepository user;
  final ChatRepository chat;
  final ReputationRepository reputation;
  final WeatherRepository weather;
  final NewsRepository news;
  final ConversatorChatRepository conversatorChat;
  final ConversatorUserRepository conversatorUser;
  final CommandStatisticsRepository commandStatistics;
  final CheckReminderRepository checkReminderRepository;

  Database(this.dbConnection)
      : user = BotUserRepository(dbConnection: dbConnection),
        chat = ChatRepository(dbConnection: dbConnection),
        reputation = ReputationRepository(dbConnection: dbConnection),
        weather = WeatherRepository(dbConnection: dbConnection),
        news = NewsRepository(dbConnection: dbConnection),
        conversatorChat = ConversatorChatRepository(dbConnection: dbConnection),
        conversatorUser = ConversatorUserRepository(dbConnection: dbConnection),
        commandStatistics = CommandStatisticsRepository(dbConnection: dbConnection),
        checkReminderRepository = CheckReminderRepository(dbConnection: dbConnection);

  Future<void> initialize() async {
    await user.initRepository();
    await chat.initRepository();
    await reputation.initRepository();
    await weather.initRepository();
    await news.initRepository();
    await conversatorChat.initRepository();
    await conversatorUser.initRepository();
    await commandStatistics.initRepository();
    await checkReminderRepository.initRepository();
  }
}
