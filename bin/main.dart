import 'dart:async';

import 'package:weather/weather.dart' as weather;
import 'package:dotenv/dotenv.dart';

void main() {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final telegramToken = env['token']!;
  final openweatherKey = env['openweather']!;
  final chatId = int.parse(env['chatid']!);
  final repoUrl = env['githubrepo']!;
  final adminId = int.parse(env['adminid']!);
  final youtubeKey = env['youtube']!;

  runZonedGuarded(() {
    var bot = weather.Bot(
        token: telegramToken, chatId: chatId, repoUrl: repoUrl, adminId: adminId, youtubeKey: youtubeKey, openweatherKey: openweatherKey);

    bot.startBot();
    bot.startNotificationPolling();
    bot.startPanoramaNewsPolling();
  }, (err, stack) {
    print('Error caught');
    print(err);
    print(stack);
  });

  // bot.startJokesPolling();
}
