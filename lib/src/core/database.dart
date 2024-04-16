import 'package:injectable/injectable.dart';
import 'package:postgres/postgres.dart';
import 'package:weather/src/utils/logger.dart';
import 'config.dart';

@singleton
class Database {
  final Config _config;
  final Logger _logger;
  final Pool _connection;

  Database(this._config, this._logger)
      : _connection = Pool.withEndpoints([
          Endpoint(
              host: _config.dbHost,
              port: _config.dbPort,
              database: _config.dbDatabase,
              username: _config.dbUser,
              password: _config.dbPassword)
        ], settings: PoolSettings(maxConnectionCount: 4, sslMode: SslMode.disable));

  // avoid using connection directly if possible
  Pool get connection => _connection;

  Future<Result?> executeQuery(String? query, [Map<String, dynamic>? parameters]) async {
    if (query == null) {
      _logger.e('Wrong query: $query');

      return null;
    }

    return _connection.execute(Sql.named(query), parameters: parameters);
  }

  Future<int> executeTransaction(String? query, [Map<String, dynamic>? parameters]) async {
    if (query == null) {
      _logger.e('Wrong query: $query');

      return 0;
    }

    int result = await _connection.runTx((ctx) async {
      var queryResult = await ctx.execute(Sql.named(query), parameters: parameters);

      return queryResult.affectedRows;
    }).catchError((error) {
      _logger.e('DB transaction error: $error');

      return 0;
    });

    return result;
  }
}
