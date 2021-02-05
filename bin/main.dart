import 'package:weather/weather.dart' as weather;
import 'package:dotenv/dotenv.dart' show load, env;

void main() {
  load();
  final telegramToken = env['token'];
  final openweatherKey = env['openweather'];
  final chatId = int.parse(env['chatid']);
  final repoUrl = env['githubrepo'];
  final adminId = int.parse(env['adminid']);

  var bot = weather.Bot(token: telegramToken, chatId: chatId, repoUrl: repoUrl, adminId: adminId);

  bot.startBot(openweatherKey);
  bot.startNotificationPolling();
  bot.startPanoramaNewsPolling();
  bot.startJokesPolling();
}
