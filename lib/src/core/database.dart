import 'package:postgres/postgres.dart';

import 'repositories/weather_repository.dart';

class Database {
  final Pool dbConnection;

  final WeatherRepository weather;

  Database(this.dbConnection) : weather = WeatherRepository(dbConnection: dbConnection);

  Future<void> initialize() async {
    await weather.initRepository();
  }
}
