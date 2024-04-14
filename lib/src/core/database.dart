import 'package:postgres/postgres.dart';

class Database {
  final Pool dbConnection;

  Database(this.dbConnection);

  Future<void> initialize() async {}
}
