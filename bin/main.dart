import 'dart:async';
import 'package:weather/src/bot.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/utils/migrations_manager.dart';
import 'package:weather/src/utils/logger.dart';

bool getIsProductionMode(String? envIsProduction) {
  return int.parse(envIsProduction ?? '0') == 1;
}

void main(List<String> args) async {
  var config = Config()..initialize();
  setupInjection(config.isProduction);

  await MigrationsManager().runMigrations();

  runZonedGuarded(() {
    Bot().startBot();
  }, (error, stack) {
    var logger = getIt<Logger>();

    logger.e('Uncaught error', error);
  });
}
