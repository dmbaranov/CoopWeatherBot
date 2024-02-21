import 'dart:async';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:weather/weather.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/utils/migrations_manager.dart';

Future<Pool> getDatabaseConnection(DotEnv env) async {
  final username = env['dbuser']!;
  final password = env['dbpassword']!;
  final database = env['dbdatabase']!;

  return Pool.withEndpoints([Endpoint(host: 'localhost', port: 5432, database: database, username: username, password: password)],
      settings: PoolSettings(maxConnectionCount: 4, sslMode: SslMode.disable));
}

Future<void> runMigrations(Pool dbConnection) async {
  MigrationsManager migrationsManager = MigrationsManager(dbConnection);

  await migrationsManager.runMigrations();
}

ChatPlatform getPlatform(String envPlatform) {
  if (envPlatform == 'telegram') return ChatPlatform.telegram;
  if (envPlatform == 'discord') return ChatPlatform.discord;

  throw Exception('Invalid platform $envPlatform');
}

void main(List<String> args) async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final dbConnection = await getDatabaseConnection(env);

  await runMigrations(dbConnection);

  runZonedGuarded(() {
    final token = env['bottoken']!;
    final adminId = env['adminid']!;
    final repoUrl = env['githubrepo']!;
    final youtubeKey = env['youtube']!;
    final openweatherKey = env['openweather']!;
    final conversatorKey = env['conversatorkey']!;
    final platformName = getPlatform(env['platform']!);

    Bot(
      platformName: platformName,
      botToken: token,
      adminId: adminId,
      repoUrl: repoUrl,
      openweatherKey: openweatherKey,
      conversatorKey: conversatorKey,
      youtubeKey: youtubeKey,
      dbConnection: dbConnection,
    ).startBot();
  }, (error, stack) {
    var now = DateTime.now();

    print('[$now]: Error caught');
    print(error);
    print(stack);
  });
}
