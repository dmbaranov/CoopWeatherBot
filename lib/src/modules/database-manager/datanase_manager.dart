import 'package:postgres/postgres.dart';

import 'entities/bot_user_entity.dart';

class DatabaseManager {
  final PostgreSQLConnection dbConnection;
  final BotUserEntity user;

  DatabaseManager(this.dbConnection) : user = BotUserEntity(dbConnection: dbConnection);

  Future<void> initialize() async {
    await user.initEntity();
  }
}
