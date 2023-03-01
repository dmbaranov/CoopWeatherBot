import 'dart:io';
import 'dart:async';

import 'package:args/args.dart';
import 'package:dotenv/dotenv.dart';
import 'package:weather/weather.dart' as weather;

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

void runDiscordBot(DotEnv env) {
  final token = env['discordtoken']!;
  final adminId = env['discordadminid']!;
  final guildId = env['discordguildid']!;
  final channelId = env['discordchannelid']!;
  final openweatherKey = env['openweather']!;

  weather.DiscordBot(token: token, adminId: adminId, guildId: guildId, channelId: channelId, openweatherKey: openweatherKey).startBot();
}

void runTelegramBot(DotEnv env) {
  final token = env['telegramtoken']!;
  final chatId = int.parse(env['telegramchatid']!);
  final repoUrl = env['githubrepo']!;
  final adminId = int.parse(env['telegramadminid']!);
  final youtubeKey = env['youtube']!;
  final openweatherKey = env['openweather']!;
  final conversatorKey = env['conversatorkey']!;

  weather.TelegramBot(
          token: token,
          chatId: chatId,
          repoUrl: repoUrl,
          adminId: adminId,
          youtubeKey: youtubeKey,
          openweatherKey: openweatherKey,
          conversatorKey: conversatorKey)
      .startBot();
}

void main(List<String> args) {
  var arguments = getRunArguments(args);
  var env = DotEnv(includePlatformEnvironment: true)..load();

  runZonedGuarded(() {
    if (arguments['platform'] == 'discord') runDiscordBot(env);
    if (arguments['platform'] == 'telegram') runTelegramBot(env);
  }, (error, stack) {
    print('Error caught');
    print(error);
    print(stack);
  });
}
