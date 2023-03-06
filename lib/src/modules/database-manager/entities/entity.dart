import 'dart:io';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';

const String _pathToQueries = 'assets/db/queries';

class Entity {
  final String entityName;
  final PostgreSQLConnection dbConnection;
  final String _queriesDirectory = _pathToQueries;

  @protected
  final Map<String, String> queriesMap = {};

  Entity({required this.entityName, required this.dbConnection});

  initEntity() async {
    var queriesLocation = Directory('$_queriesDirectory/$entityName');
    var rawQueriesContent = await queriesLocation.list().toList();
    var queries = rawQueriesContent.whereType<File>();

    await Future.forEach(queries, (query) async {
      var queryName = query.uri.pathSegments.last.split('.')[0];
      var queryContent = await query.readAsString();

      queriesMap[queryName] = queryContent;
    });
  }

  @protected
  executeQuery(String? query) async {
    if (query == null) {
      print('Wrong query $query');

      return;
    }

    return dbConnection.query(query);
  }
}
