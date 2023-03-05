import 'dart:io';
import 'package:postgres/postgres.dart';

const String _pathToMigrations = 'assets/migrations';
const List<String> _alwaysRunMigrations = ['1677944890_migration.sql'];

class MigrationsManager {
  final PostgreSQLConnection dbConnection;
  final String _migrationsDirectory = _pathToMigrations;

  MigrationsManager(this.dbConnection);

  Future<void> runMigrations() async {
    var migrationsLocation = Directory(_migrationsDirectory);
    var migrationEntities = await migrationsLocation.list().toList()
      ..sort((a, b) => a.uri.pathSegments.last.compareTo(b.uri.pathSegments.last));
    var migrations = migrationEntities.whereType<File>();

    await Future.forEach(migrations, (migration) async {
      var migrationName = migration.uri.pathSegments.last;
      var runMigration = await _shouldRunMigration(migrationName);

      if (runMigration) {
        print('Applying migration $migrationName');
        var query = await migration.readAsString();

        await _runMigration(query, migrationName);
      }
    });
  }

  Future<bool> _shouldRunMigration(String migrationName) async {
    if (_alwaysRunMigrations.contains(migrationName)) return true;

    var savedMigration = await dbConnection
        .query('SELECT id FROM migration WHERE name = @migrationName', substitutionValues: {'migrationName': migrationName});

    return savedMigration.isEmpty;
  }

  Future<void> _runMigration(String query, String migrationName) async {
    await dbConnection.query(query);
    await dbConnection.query('INSERT INTO migration(name) VALUES(@migrationName)', substitutionValues: {'migrationName': migrationName});
  }
}
