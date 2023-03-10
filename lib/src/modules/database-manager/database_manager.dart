import 'package:postgres/postgres.dart';

import 'entities/bot_user_entity.dart';
import 'entities/chat_entity.dart';

class DatabaseManager {
  final PostgreSQLConnection dbConnection;
  final BotUserEntity user;
  final ChatEntity chat;

  DatabaseManager(this.dbConnection)
      : user = BotUserEntity(dbConnection: dbConnection),
        chat = ChatEntity(dbConnection: dbConnection);

  Future<void> initialize() async {
    await user.initEntity();
    await chat.initEntity();
  }
}
