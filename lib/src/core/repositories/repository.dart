import 'dart:io';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/utils/logger.dart';

const String _pathToQueries = 'assets/db/queries';

class Repository {
  final String repositoryName;
  final Pool dbConnection;
  final Logger _logger;
  final String _queriesDirectory = _pathToQueries;

  @protected
  final Map<String, String> queriesMap = {};

  Repository({required this.repositoryName, required this.dbConnection}) : _logger = getIt<Logger>();

  initRepository() async {
    var queriesLocation = Directory('$_queriesDirectory/$repositoryName');
    var rawQueriesContent = await queriesLocation.list().toList();
    var queries = rawQueriesContent.whereType<File>();

    await Future.forEach(queries, (query) async {
      var queryName = query.uri.pathSegments.last.split('.')[0];
      var queryContent = await query.readAsString();

      queriesMap[queryName] = queryContent;
    });
  }

  @protected
  Future<Result?> executeQuery(String? query, [Map<String, dynamic>? parameters]) async {
    if (query == null) {
      _logger.e('Wrong query: $query');

      return null;
    }

    return dbConnection.execute(Sql.named(query), parameters: parameters);
  }

  @protected
  Future<int> executeTransaction(String? query, [Map<String, dynamic>? parameters]) async {
    if (query == null) {
      _logger.e('Wrong query: $query');

      return 0;
    }

    int result = await dbConnection.runTx((ctx) async {
      var queryResult = await ctx.execute(Sql.named(query), parameters: parameters);

      return queryResult.affectedRows;
    }).catchError((error) {
      _logger.e('DB transaction error: $error');

      return 0;
    });

    return result;
  }
}
