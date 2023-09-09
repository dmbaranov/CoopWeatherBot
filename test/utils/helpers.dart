import 'package:postgres/postgres.dart';

List<PostgreSQLResultRow> sortResults(PostgreSQLResult results) {
  return results.toList()..sort((a, b) => a[0].toString().compareTo(b[0].toString()));
}
