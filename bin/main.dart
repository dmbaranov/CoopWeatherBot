import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';
import 'package:weather/weather.dart' as weather;
import 'package:dotenv/dotenv.dart';

ArgResults getRunArguments(List<String> args) {
  var parser = ArgParser()..addOption('platform', abbr: 'p', allowed: ['discord', 'telegram'], mandatory: true);

  var parsedArguments;

  try {
    parsedArguments = parser.parse(args);
  } on FormatException {
    print('Error: Pass -p parameter to specify discord or telegram version');
    exit(1);
  }

  return parsedArguments;
}

void main(List<String> args) {
  var arguments = getRunArguments(args);
  var env = DotEnv(includePlatformEnvironment: true)..load();

  final telegramToken = env['telegramtoken']!;
  final discordToken = env['discordtoken']!;
  final openweatherKey = env['openweather']!;
  final chatId = int.parse(env['telegramchatid']!);
  final guildId = env['discordguildid']!;
  final repoUrl = env['githubrepo']!;
  final adminId = int.parse(env['telegramadminid']!);
  final youtubeKey = env['youtube']!;

  runZonedGuarded(() {
    if (arguments['platform'] == 'discord') {
      weather.DiscordBot(token: discordToken, guildId: guildId)
        ..startBot()
        ..startAwakeUsersPolling();
    }
    if (arguments['platform'] == 'telegram') {
      weather.TelegramBot(
          token: telegramToken, chatId: chatId, repoUrl: repoUrl, adminId: adminId, youtubeKey: youtubeKey, openweatherKey: openweatherKey)
        ..startBot()
        ..startNotificationPolling()
        ..startPanoramaNewsPolling();
    }
  }, (error, stack) {
    print('Error caught');
    print(error);
    print(stack);
  });
}
