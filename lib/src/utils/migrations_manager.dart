import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/utils/logger.dart';

const String _pathToMigrations = 'assets/db/migrations';
const String _migrationTableMigrationName = '1677944890_migration.sql';

class MigrationsManager {
  final Pool dbConnection;
  final Logger _logger;
  final String _migrationsDirectory = _pathToMigrations;

  MigrationsManager(this.dbConnection) : _logger = getIt<Logger>();

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
    var migrationTable = await dbConnection.execute("SELECT * FROM information_schema.tables WHERE table_name = 'migration'");

    if (migrationTable.isEmpty) {
      var query = await migration.readAsString();
      await _runMigration(query, _migrationTableMigrationName);
    }
  }

  Future<bool> _shouldRunMigration(String migrationName) async {
    var savedMigration = await dbConnection
        .execute(Sql.named('SELECT id FROM migration WHERE name = @migrationName'), parameters: {'migrationName': migrationName});

    return savedMigration.isEmpty;
  }

  Future<void> _runMigration(String query, String migrationName) async {
    await dbConnection.runTx((ctx) async {
      await ctx.execute(Sql.named(query));
      await ctx.execute(Sql.named('INSERT INTO migration(name) VALUES(@migrationName)'), parameters: {'migrationName': migrationName});
    });
  }
}
