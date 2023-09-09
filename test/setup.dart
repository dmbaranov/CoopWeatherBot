import 'dart:io';
import 'package:docker_process/containers/postgres.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:weather/src/utils/migrations_manager.dart';

const _containerName = 'postgres-dart-test';
const _testDbName = 'wb_test';
const _testDbUser = 'postgres';
const _testDbPassword = 'postgres';

void setupTestEnvironment() {
  setUpAll(() async {
    var isRunning = await _isPostgresContainerRunning();

    if (isRunning) {
      return;
    }

    await startPostgres(
      name: _containerName,
      version: 'latest',
      pgPort: 5433,
      pgDatabase: _testDbName,
      pgUser: _testDbUser,
      pgPassword: _testDbPassword,
      cleanup: true,
    );

    var dbConnection = PostgreSQLConnection('localhost', 5433, _testDbName, username: _testDbUser, password: _testDbPassword);
    await dbConnection.open();

    await MigrationsManager(dbConnection).runMigrations();
  });

  tearDownAll(() async {
    print('Shutting down docker container');
    await Process.run('docker', ['stop', _containerName]);
  });
}

Future<bool> _isPostgresContainerRunning() async {
  final pr = await Process.run(
    'docker',
    ['ps', '--format', '{{.Names}}'],
  );

  return pr.stdout.toString().split('\n').map((s) => s.trim()).contains(_containerName);
}

var connection;

Future<PostgreSQLConnection> getConnection() async {
  if (connection == null) {
    connection = PostgreSQLConnection('localhost', 5433, _testDbName, username: _testDbUser, password: _testDbPassword);
    await connection.open();

    return connection;
  }

  return connection;
}
