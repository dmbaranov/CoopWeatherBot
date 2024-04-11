import 'dart:io';
import 'package:meta/meta.dart';
import 'package:weather/src/core/database_inj.dart';

const String _pathToQueries = 'assets/db/queries';

class RepositoryInjTwo {
  final String repositoryName;
  final DatabaseInj db;
  final Map<String, String> queriesMap = {};
  final String _queriesDirectory = _pathToQueries;

  RepositoryInjTwo({required this.db, required this.repositoryName}) {
    initRepository();
  }

  @protected
  initRepository() {
    var queriesLocation = Directory('$_queriesDirectory/$repositoryName');
    var rawQueriesContent = queriesLocation.listSync().toList();
    var queries = rawQueriesContent.whereType<File>();

    queries.forEach((query) {
      var queryName = query.uri.pathSegments.last.split('.')[0];
      var queryContent = query.readAsStringSync();

      queriesMap[queryName] = queryContent;
    });
  }
}
