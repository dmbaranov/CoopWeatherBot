import 'package:postgres/postgres.dart';

import 'entities/bot_user_entity.dart';
import 'entities/chat_entity.dart';
import 'entities/reputation_entity.dart';
import 'entities/weather_entity.dart';
import 'entities/news_entity.dart';
import 'entities/conversator_chat_entity.dart';
import 'entities/conversator_user_entity.dart';

class Database {
  final PostgreSQLConnection dbConnection;
  final BotUserEntity user;
  final ChatEntity chat;
  final ReputationEntity reputation;
  final WeatherEntity weather;
  final NewsEntity news;
  final ConversatorChatEntity conversatorChat;
  final ConversatorUserEntity conversatorUser;

  Database(this.dbConnection)
      : user = BotUserEntity(dbConnection: dbConnection),
        chat = ChatEntity(dbConnection: dbConnection),
        reputation = ReputationEntity(dbConnection: dbConnection),
        weather = WeatherEntity(dbConnection: dbConnection),
        news = NewsEntity(dbConnection: dbConnection),
        conversatorChat = ConversatorChatEntity(dbConnection: dbConnection),
        conversatorUser = ConversatorUserEntity(dbConnection: dbConnection);

  Future<void> initialize() async {
    await user.initEntity();
    await chat.initEntity();
    await reputation.initEntity();
    await weather.initEntity();
    await news.initEntity();
    await conversatorChat.initEntity();
    await conversatorUser.initEntity();
  }
}
