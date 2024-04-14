import 'package:postgres/postgres.dart';

import 'repositories/reputation_repository.dart';
import 'repositories/weather_repository.dart';

class Database {
  final Pool dbConnection;

  final ReputationRepository reputation;
  final WeatherRepository weather;

  Database(this.dbConnection)
      : reputation = ReputationRepository(dbConnection: dbConnection),
        weather = WeatherRepository(dbConnection: dbConnection);

  Future<void> initialize() async {
    await reputation.initRepository();
    await weather.initRepository();
  }
}
