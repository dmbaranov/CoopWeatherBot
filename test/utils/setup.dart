import 'dart:io';
import 'package:docker_process/containers/postgres.dart';
import 'package:test/test.dart';
import 'package:weather/src/utils/migrations_manager.dart';
import 'constants.dart';
import 'db_connection.dart';

const _containerName = 'postgres-dart-test';

void setupTestEnvironment() {
  setUpAll(() async {
    var dockerRunning = await _isDockerContainerRunning();

    if (!dockerRunning) {
      await startPostgres(
        name: _containerName,
        version: 'latest',
        pgPort: testDbPort,
        pgDatabase: testDbName,
        pgUser: testDbUser,
        pgPassword: testDbPassword,
        cleanup: true,
      );
    }

    var dbConnection = DbConnection.connection;
    await dbConnection.open();

    await MigrationsManager(dbConnection).runMigrations();
  });

  tearDownAll(() async {
    await DbConnection.connection.query('DROP SCHEMA public CASCADE;');
    await DbConnection.connection.query('CREATE SCHEMA public;');
  });
}

Future<bool> _isDockerContainerRunning() async {
  final pr = await Process.run(
    'docker',
    ['ps', '--format', '{{.Names}}'],
  );

  return pr.stdout.toString().split('\n').map((s) => s.trim()).contains(_containerName);
}
