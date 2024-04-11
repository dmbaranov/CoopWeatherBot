import 'dart:io';

import 'package:postgres/postgres.dart';
import 'package:weather/src/core/database_inj.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/utils/logger.dart';

const String _pathToMigrations = 'assets/db/migrations';
const String _migrationTableMigrationName = '1677944890_migration.sql';

class MigrationsManager {
  final Logger _logger;
  final DatabaseInj _db;
  final String _migrationsDirectory = _pathToMigrations;

  MigrationsManager()
      : _logger = getIt<Logger>(),
        _db = getIt<DatabaseInj>();

  Future<void> runMigrations() async {
    var migrationsLocation = Directory(_migrationsDirectory);
    var rawMigrationsContent = await migrationsLocation.list().toList()
      ..sort((a, b) => a.uri.pathSegments.last.compareTo(b.uri.pathSegments.last));
    var migrations = rawMigrationsContent.whereType<File>();

    await Future.forEach(migrations, (migration) async {
      var migrationName = migration.uri.pathSegments.last;

      if (migrationName == _migrationTableMigrationName) {
        return _createMigrationsTableIfNeeded(migration);
      }

      var runMigration = await _shouldRunMigration(migrationName);

      if (runMigration) {
        _logger.w('Applying migration $migrationName');
        var query = await migration.readAsString();

        await _runMigration(query, migrationName);
      }
    });
  }

  Future<void> _createMigrationsTableIfNeeded(File migration) async {
    var migrationTable = await _db.connection.execute("SELECT * FROM information_schema.tables WHERE table_name = 'migration'");

    if (migrationTable.isEmpty) {
      var query = await migration.readAsString();
      await _runMigration(query, _migrationTableMigrationName);
    }
  }

  Future<bool> _shouldRunMigration(String migrationName) async {
    var savedMigration = await _db.connection
        .execute(Sql.named('SELECT id FROM migration WHERE name = @migrationName'), parameters: {'migrationName': migrationName});

    return savedMigration.isEmpty;
  }

  Future<void> _runMigration(String query, String migrationName) async {
    await _db.connection.runTx((ctx) async {
      await ctx.execute(Sql.named(query));
      await ctx.execute(Sql.named('INSERT INTO migration(name) VALUES(@migrationName)'), parameters: {'migrationName': migrationName});
    });
  }
}
