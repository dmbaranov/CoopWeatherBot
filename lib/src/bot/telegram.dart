import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';

import 'bot.dart';
import 'package:weather/src/modules/commands_manager.dart';

class TelegramBot extends Bot {
  late TeleDart bot;
  late Telegram telegram;

  TelegramBot(
      {required super.botToken,
      required super.repoUrl,
      required super.openweatherKey,
      required super.conversatorKey,
      required super.dbConnection,
      required super.youtubeKey});

  @override
  Future<void> startBot() async {
    await super.startBot();

    var botName = (await Telegram(botToken).getMe()).username;

    telegram = Telegram(botToken);
    bot = TeleDart(botToken, Event(botName!), fetcher: LongPolling(Telegram(botToken), limit: 100, timeout: 50));

    setupCommands();

    bot.start();

    print('Telegram bot has been started!');
  }

  @override
  Future<void> sendMessage(String chatId, String message) async {
    await telegram.sendMessage(chatId, message);
  }

  @override
  void setupCommands() {
    bot.onCommand('addcity').listen(
        (event) => commandsManager.userCommand(mapPlatformEventToMessageEvent(event), onSuccess: addCity, onFailure: sendNoAccessMessage));
  }

  @override
  MessageEvent mapPlatformEventToMessageEvent(rawEvent) {
    TeleDartMessage event = rawEvent as TeleDartMessage;

    return MessageEvent(
        chatId: event.chat.id.toString(),
        userId: event.from?.id.toString(),
        isBot: event.from?.isBot,
        message: event.text,
        selectedUserId: event.replyToMessage?.from?.id.toString());
  }

  sendNoAccessMessage(MessageEvent event) {
    sendMessage(event.chatId, 'No access');
  }
}
