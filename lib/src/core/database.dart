import 'package:postgres/postgres.dart';

import 'repositories/reputation_repository.dart';
import 'repositories/weather_repository.dart';
import 'repositories/news_repository.dart';
import 'repositories/conversator_chat_repository.dart';
import 'repositories/conversator_user_repository.dart';

class Database {
  final Pool dbConnection;

  final ReputationRepository reputation;
  final WeatherRepository weather;
  final NewsRepository news;
  final ConversatorChatRepository conversatorChat;
  final ConversatorUserRepository conversatorUser;

  Database(this.dbConnection)
      : reputation = ReputationRepository(dbConnection: dbConnection),
        weather = WeatherRepository(dbConnection: dbConnection),
        news = NewsRepository(dbConnection: dbConnection),
        conversatorChat = ConversatorChatRepository(dbConnection: dbConnection),
        conversatorUser = ConversatorUserRepository(dbConnection: dbConnection);

  Future<void> initialize() async {
    await reputation.initRepository();
    await weather.initRepository();
    await news.initRepository();
    await conversatorChat.initRepository();
    await conversatorUser.initRepository();
  }
}
