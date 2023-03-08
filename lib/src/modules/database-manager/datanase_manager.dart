import 'package:postgres/postgres.dart';

import 'entities/user_entity.dart';

class DatabaseManager {
  final PostgreSQLConnection dbConnection;
  final UserEntity user;

  DatabaseManager(this.dbConnection) : user = UserEntity(dbConnection: dbConnection);

  Future<void> initialize() async {
    await user.initEntity();
  }
}
