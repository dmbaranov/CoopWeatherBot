import 'package:weather/weather.dart' as weather;
import 'package:dotenv/dotenv.dart' show load, env;

void main() {
  load();
  final telegramToken = env['token'];
  final openweatherKey = env['openweather'];
  final chatId = int.parse(env['chatid']);
  final repoUrl = env['githubrepo'];

  var bot = weather.Bot(token: telegramToken, chatId: chatId, repoUrl: repoUrl);

  bot.startBot(openweatherKey);
  bot.startNotificationPolling();
  bot.startPanoramaNewsPolling();
}
