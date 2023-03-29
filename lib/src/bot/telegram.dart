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
  setupCommands() {
    bot.onCommand('addcity').listen(
        (event) => cm.userCommand(mapToMessageEventWithParameters(event), onSuccess: addWeatherCity, onFailure: sendNoAccessMessage));
    bot.onCommand('removecity').listen(
        (event) => cm.userCommand(mapToMessageEventWithParameters(event), onSuccess: removeWeatherCity, onFailure: sendNoAccessMessage));
    bot
        .onCommand('watchlist')
        .listen((event) => cm.userCommand(mapToGeneralMessageEvent(event), onSuccess: getWeatherWatchlist, onFailure: sendNoAccessMessage));
    bot.onCommand('getweather').listen(
        (event) => cm.userCommand(mapToMessageEventWithParameters(event), onSuccess: getWeatherForCity, onFailure: sendNoAccessMessage));
    bot.onCommand('setnotificationhour').listen((event) =>
        cm.moderatorCommand(mapToMessageEventWithParameters(event), onSuccess: setWeatherNotificationHour, onFailure: sendNoAccessMessage));
    bot.onCommand('write').listen(
        (event) => cm.moderatorCommand(mapToMessageEventWithParameters(event), onSuccess: writeToChat, onFailure: sendNoAccessMessage));
    bot
        .onCommand('updatemessage')
        .listen((event) => cm.adminCommand(mapToGeneralMessageEvent(event), onSuccess: postUpdateMessage, onFailure: sendNoAccessMessage));
    bot.onCommand('increp').listen(
        (event) => cm.userCommand(mapToReputationMessageEvent(event), onSuccess: increaseReputation, onFailure: sendNoAccessMessage));
  }

  MessageEvent mapToGeneralMessageEvent(TeleDartMessage event) {
    return MessageEvent(
        chatId: event.chat.id.toString(),
        userId: event.from?.id.toString(),
        isBot: event.from?.isBot,
        message: event.text,
        otherUserIds: [],
        parameters: []);
  }

  MessageEvent mapToMessageEventWithParameters(TeleDartMessage event) {
    List<String> parameters = event.text?.split(' ').sublist(1).toList() ?? [];

    return mapToGeneralMessageEvent(event)..parameters.addAll(parameters);
  }

  MessageEvent mapToReputationMessageEvent(TeleDartMessage event) {
    return mapToGeneralMessageEvent(event)..otherUserIds.add(event.replyToMessage?.from?.id.toString() ?? '');
  }
}
