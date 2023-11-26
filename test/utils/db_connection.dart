import 'package:postgres/postgres.dart';
import 'constants.dart';

class DbConnection {
  static Pool connection = Pool.withEndpoints(
      [Endpoint(host: testDbHost, port: testDbPort, database: testDbName, username: testDbUser, password: testDbPassword)],
      settings: PoolSettings(sslMode: SslMode.disable));
}
