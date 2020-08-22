import 'package:weather/weather.dart' as weather;
import 'package:dotenv/dotenv.dart' show load, env;

void main() {
  load();
  final telegramToken = env['token'];
  final openweatherKey = env['openweather'];
  final chatId = env['chatid'];

  var bot = weather.Bot(telegramToken);

  bot.startBot(openweatherKey);
  bot.startNotificationPolling(int.parse(chatId));
}
