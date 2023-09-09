import 'dart:io';
import 'package:docker_process/containers/postgres.dart';
import 'package:path/path.dart' as p;
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:weather/src/utils/migrations_manager.dart';

const _kContainerName = 'postgres-dart-test';

void runDocker() {
  setUpAll(() async {
    final isRunning = await _isPostgresContainerRunning();
    if (isRunning) {
      return;
    }

    print('Starting docker container');

    // final configPath = p.join(Directory.current.path, 'test', 'pg_configs');

    final dp = await startPostgres(
      name: _kContainerName,
      version: 'latest',
      pgPort: 5433,
      pgDatabase: 'postgres',
      pgUser: 'postgres',
      pgPassword: 'postgres',
      cleanup: true,
      configurations: [
        // // SSL settings
        // 'ssl=on',
        // // The debian image includes a self-signed SSL cert that can be used:
        // 'ssl_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem',
        // 'ssl_key_file=/etc/ssl/private/ssl-cert-snakeoil.key',
      ],
      // pgHbaConfPath: p.join(configPath, 'pg_hba.conf'),
      // postgresqlConfPath: p.join(configPath, 'postgresql.conf'),
    );

    // Setup the database to support all kind of tests
    // see _setupDatabaseStatements definition for details
    for (final stmt in _setupDatabaseStatements) {
      final args = [
        'psql',
        '-c',
        stmt,
        '-U',
        'postgres',
      ];
      final res = await dp.exec(args);
      if (res.exitCode != 0) {
        final message = 'Failed to setup PostgreSQL database due to the following error:\n'
            '${res.stderr}';
        throw ProcessException(
          'docker exec $_kContainerName',
          args,
          message,
          res.exitCode,
        );
      }
    }

    // var data = await dp.exec(['psql', '-c', 'SELECT datname FROM pg_catalog.pg_database;', '-U', 'postgres']);
    // print(data);
    // var connection = PostgreSQLConnection('localhost', '5432', databaseName)

    var dbConnection = PostgreSQLConnection('localhost', 5433, 'wb_test', username: 'postgres', password: 'postgres');
    await dbConnection.open();

    await MigrationsManager(dbConnection).runMigrations();
  });

  tearDownAll(() async {
    print('Shutting down docker container');
    await Process.run('docker', ['stop', _kContainerName]);
  });
}

Future<bool> _isPostgresContainerRunning() async {
  final pr = await Process.run(
    'docker',
    ['ps', '--format', '{{.Names}}'],
  );

  return pr.stdout.toString().split('\n').map((s) => s.trim()).contains(_kContainerName);
}

// This setup supports old and new test
// This is setup is the same as the one from the old travis ci except for the
// replication user which is a new addition.
final _setupDatabaseStatements = <String>[
  // create testing database
  'create database wb_test;',
  // create dart user
  // 'create user wb_test_user with createdb;',
  // "alter user wb_test_user with password 'wb_test_password';",
  // 'grant all on database wb_test to wb_test_user;',
];

var connection;

Future<PostgreSQLConnection> getConnection() async {
  if (connection == null) {
    connection = PostgreSQLConnection('localhost', 5433, 'wb_test', username: 'postgres', password: 'postgres');
    await connection.open();

    return connection;
  }

  return connection;
}
