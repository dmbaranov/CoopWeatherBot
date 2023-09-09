import 'package:postgres/postgres.dart';
import 'constants.dart';

class DbConnection {
  static late PostgreSQLConnection connection;

  DbConnection._();

  static final DbConnection _instance = DbConnection._();

  factory DbConnection() {
    connection = PostgreSQLConnection(testDbHost, testDbPort, testDbName, username: testDbUser, password: testDbPassword);

    return _instance;
  }
}
