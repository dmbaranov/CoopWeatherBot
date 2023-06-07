import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

Future<TeleDart> initializeTelegram(String token) async {
  var botName = (await Telegram(token).getMe()).username;
  var telegram = Telegram(token); // TODO: needs to be returned as well?
  var bot = TeleDart(token, Event(botName!), fetcher: LongPolling(Telegram(token), limit: 100, timeout: 50));

  bot.start();

  return bot;
}
