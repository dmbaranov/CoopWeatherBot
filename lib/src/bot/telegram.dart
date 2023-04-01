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
    bot
        .onCommand('sendnews')
        .listen((event) => cm.userCommand(mapToGeneralMessageEvent(event), onSuccess: sendNewsToChat, onFailure: sendNoAccessMessage));
    bot
        .onCommand('sendjoke')
        .listen((event) => cm.userCommand(mapToGeneralMessageEvent(event), onSuccess: sendJokeToChat, onFailure: sendNoAccessMessage));
    bot.onCommand('sendrealmusic').listen(
        (event) => cm.userCommand(mapToMessageEventWithParameters(event), onSuccess: sendRealMusicToChat, onFailure: sendNoAccessMessage));
    bot.onCommand('increp').listen(
        (event) => cm.userCommand(mapToEventWithOtherUserIds(event), onSuccess: increaseReputation, onFailure: sendNoAccessMessage));
    bot.onCommand('decrep').listen(
        (event) => cm.userCommand(mapToEventWithOtherUserIds(event), onSuccess: decreaseReputation, onFailure: sendNoAccessMessage));
    bot
        .onCommand('replist')
        .listen((event) => cm.userCommand(mapToGeneralMessageEvent(event), onSuccess: sendReputationList, onFailure: sendNoAccessMessage));
    bot.onCommand('searchsong').listen(
        (event) => cm.userCommand(mapToMessageEventWithParameters(event), onSuccess: searchYoutubeTrack, onFailure: sendNoAccessMessage));
    bot
        .onCommand('na')
        .listen((event) => cm.userCommand(mapToGeneralMessageEvent(event), onSuccess: healthCheck, onFailure: sendNoAccessMessage));
    bot.onCommand('accordion').listen(
        (event) => cm.userCommand(mapToAccordionMessageEvent(event), onSuccess: startAccordionPoll, onFailure: sendNoAccessMessage));
    bot.onCommand('ask').listen(
        (event) => cm.userCommand(mapToMessageEventWithParameters(event), onSuccess: askConversator, onFailure: sendNoAccessMessage));
    bot
        .onCommand('adduser')
        .listen((event) => cm.moderatorCommand(mapToEventWithOtherUserIds(event), onSuccess: addUser, onFailure: sendNoAccessMessage));
    bot
        .onCommand('removeuser')
        .listen((event) => cm.moderatorCommand(mapToEventWithOtherUserIds(event), onSuccess: removeUser, onFailure: sendNoAccessMessage));
    bot
        .onCommand('initialize')
        .listen((event) => cm.adminCommand(mapToGeneralMessageEvent(event), onSuccess: initializeChat, onFailure: sendNoAccessMessage));
    bot
        .onCommand('createreputation')
        .listen((event) => cm.adminCommand(mapToGeneralMessageEvent(event), onSuccess: createReputation, onFailure: sendNoAccessMessage));
    bot
        .onCommand('createweather')
        .listen((event) => cm.adminCommand(mapToGeneralMessageEvent(event), onSuccess: createWeather, onFailure: sendNoAccessMessage));
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

  MessageEvent mapToEventWithOtherUserIds(TeleDartMessage event) {
    return mapToGeneralMessageEvent(event)..otherUserIds.add(event.replyToMessage?.from?.id.toString() ?? '');
  }

  MessageEvent mapToAccordionMessageEvent(TeleDartMessage event) {
    return mapToGeneralMessageEvent(event)..parameters.add(event.replyToMessage?.from?.id.toString() ?? '');
  }
}
