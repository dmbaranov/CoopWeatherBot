import 'package:postgres/postgres.dart';

import 'repositories/bot_user_repository.dart';
import 'repositories/chat_repository.dart';
import 'repositories/reputation_repository.dart';
import 'repositories/weather_repository.dart';
import 'repositories/news_repository.dart';
import 'repositories/conversator_chat_repository.dart';
import 'repositories/conversator_user_repository.dart';
import 'repositories/commands_statistics_repository.dart';

class Database {
  final PostgreSQLConnection dbConnection;
  final BotUserRepository user;
  final ChatRepository chat;
  final ReputationRepository reputation;
  final WeatherRepository weather;
  final NewsRepository news;
  final ConversatorChatRepository conversatorChat;
  final ConversatorUserRepository conversatorUser;
  final CommandsStatisticsRepository commandsStatistics;

  Database(this.dbConnection)
      : user = BotUserRepository(dbConnection: dbConnection),
        chat = ChatRepository(dbConnection: dbConnection),
        reputation = ReputationRepository(dbConnection: dbConnection),
        weather = WeatherRepository(dbConnection: dbConnection),
        news = NewsRepository(dbConnection: dbConnection),
        conversatorChat = ConversatorChatRepository(dbConnection: dbConnection),
        conversatorUser = ConversatorUserRepository(dbConnection: dbConnection),
        commandsStatistics = CommandsStatisticsRepository(dbConnection: dbConnection);

  Future<void> initialize() async {
    await user.initRepository();
    await chat.initRepository();
    await reputation.initRepository();
    await weather.initRepository();
    await news.initRepository();
    await conversatorChat.initRepository();
    await conversatorUser.initRepository();
    await commandsStatistics.initRepository();
  }
}
