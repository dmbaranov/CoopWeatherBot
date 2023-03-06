import 'package:postgres/postgres.dart';

class DatabaseManager {
  final PostgreSQLConnection dbConnection;

  DatabaseManager(this.dbConnection);
}
