import 'package:postgres/postgres.dart';
import 'constants.dart';

class DbConnection {
  late PostgreSQLConnection connection;

  DbConnection._();

  static final DbConnection _instance = DbConnection._();

  factory DbConnection() {
    return _instance..connection = PostgreSQLConnection(testDbHost, testDbPort, testDbName, username: testDbUser, password: testDbPassword);
  }
}
