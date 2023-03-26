import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:weather/weather.dart' as weather;
import 'package:weather/src/utils/migrations_manager.dart';

Future<PostgreSQLConnection> getDatabaseConnection(DotEnv env) async {
  final username = env['dbuser']!;
  final password = env['dbpassword']!;
  final database = env['dbdatabase']!;

  var connection = PostgreSQLConnection('localhost', 5432, database, username: username, password: password);
  await connection.open();

  return connection;
}

ArgResults getRunArguments(List<String> args) {
  var parser = ArgParser()..addOption('platform', abbr: 'p', allowed: ['discord', 'telegram'], mandatory: true);

  ArgResults parsedArguments;

  try {
    parsedArguments = parser.parse(args);
  } on FormatException {
    print('Error: Pass -p parameter to specify discord or telegram version');
    exit(1);
  }

  return parsedArguments;
}

Future<void> runMigrations(PostgreSQLConnection dbConnection) async {
  MigrationsManager migrationsManager = MigrationsManager(dbConnection);

  await migrationsManager.runMigrations();
}

void runDiscordBot(DotEnv env, PostgreSQLConnection dbConnection) {
  final token = env['discordtoken']!;
  final adminId = env['discordadminid']!;
  final openweatherKey = env['openweather']!;
  final conversatorKey = env['conversatorkey']!;

  weather.DiscordBot(
          token: token, adminId: adminId, openweatherKey: openweatherKey, conversatorKey: conversatorKey, dbConnection: dbConnection)
      .startBot();
}

void runTelegramBot(DotEnv env, PostgreSQLConnection dbConnection) {
  final token = env['telegramtoken']!;
  final repoUrl = env['githubrepo']!;
  final adminId = int.parse(env['telegramadminid']!);
  final youtubeKey = env['youtube']!;
  final openweatherKey = env['openweather']!;
  final conversatorKey = env['conversatorkey']!;

  weather.TelegramBot(
          botToken: token,
          repoUrl: repoUrl,
          openweatherKey: openweatherKey,
          conversatorKey: conversatorKey,
          youtubeKey: youtubeKey,
          dbConnection: dbConnection)
      .startBot();
  // weather.TelegramBot(
  //         token: token,
  //         repoUrl: repoUrl,
  //         adminId: adminId,
  //         youtubeKey: youtubeKey,
  //         openweatherKey: openweatherKey,
  //         conversatorKey: conversatorKey,
  //         dbConnection: dbConnection)
  //     .startBot();
}

void main(List<String> args) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();

  final dbConnection = await getDatabaseConnection(env);
  var arguments = getRunArguments(args);

  await runMigrations(dbConnection);

  runZonedGuarded(() {
    if (arguments['platform'] == 'discord') runDiscordBot(env, dbConnection);
    if (arguments['platform'] == 'telegram') runTelegramBot(env, dbConnection);
  }, (error, stack) {
    var now = DateTime.now();

    print('[$now]: Error caught');
    print(error);
    print(stack);
  });
}
