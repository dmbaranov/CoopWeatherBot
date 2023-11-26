import 'dart:io';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';

const String _pathToQueries = 'assets/db/queries';

class Repository {
  final String repositoryName;
  final Pool dbConnection;
  final String _queriesDirectory = _pathToQueries;

  @protected
  final Map<String, String> queriesMap = {};

  Repository({required this.repositoryName, required this.dbConnection});

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
      print('Wrong query $query');

      return null;
    }

    return dbConnection.execute(Sql.named(query), parameters: parameters);
  }

  @protected
  Future<int> executeTransaction(String? query, [Map<String, dynamic>? parameters]) async {
    if (query == null) {
      print('Wrong query $query');

      return 0;
    }

    int result = await dbConnection.runTx((ctx) async {
      var queryResult = await ctx.execute(Sql.named(query), parameters: parameters);

      return queryResult.affectedRows;
    }).catchError((error) {
      print('DB transaction error');
      print(error);

      return 0;
    });

    return result;
  }
}
