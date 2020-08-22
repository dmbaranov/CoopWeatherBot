import 'package:weather/weather.dart' as weather;
import 'package:dotenv/dotenv.dart' show load, env;

void main() {
  load();
  final token = env['token'];

  var bot = weather.Bot(token);

  bot.startBot();
}
