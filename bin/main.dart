import 'dart:async';

// import 'package:weather/src/core/database.dart';
// import 'package:weather/weather.dart';
import 'package:weather/src/core/database_inj.dart';
import 'package:weather/src/core/repositories/bot_user_repository_inj.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/config.dart';

// import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/utils/migrations_manager.dart';
// import 'package:weather/src/utils/logger.dart';

// Future<void> runMigrations() async {
//   MigrationsManager migrationsManager = MigrationsManager();
//
//   await migrationsManager.runMigrations();
// }

// ChatPlatform getPlatform(String? envPlatform) {
//   if (envPlatform == 'telegram') return ChatPlatform.telegram;
//   if (envPlatform == 'discord') return ChatPlatform.discord;
//
//   throw Exception('Invalid platform $envPlatform');
// }

bool getIsProductionMode(String? envIsProduction) {
  return int.parse(envIsProduction ?? '0') == 1;
}

void main(List<String> args) async {
  var config = Config()..initialize();
  setupInjection(config.isProduction);

  await MigrationsManager().runMigrations();

  // var config = Config()..initialize();
  // await Database().initialize();

  // var test = getIt<Config>();
  // print(test.dbUser);
  // var test = getIt<DatabaseInj>();
  //
  // var result = await test.executeQuery('SELECT * FROM bot_user;');
  // print(result);
  
  // var repo = getIt<BotUserRepositoryInj>();
  //
  // var result = await repo.getAllUsersForChat('123');
  //
  // print(result.first.name);
  
  // test2.initialize();
  //

  // await runMigrations();
  //
  // runZonedGuarded(() {
  //   // Bot().startBot();
  //   Bot();
  // }, (error, stack) {
  //   var logger = getIt<Logger>();
  //
  //   logger.e('Uncaught error', error);
  // });
}
