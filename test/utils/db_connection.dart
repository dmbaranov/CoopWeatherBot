import 'package:postgres/postgres.dart';
import 'constants.dart';

class DbConnection {
  static PostgreSQLConnection connection =
      PostgreSQLConnection(testDbHost, testDbPort, testDbName, username: testDbUser, password: testDbPassword);
}
