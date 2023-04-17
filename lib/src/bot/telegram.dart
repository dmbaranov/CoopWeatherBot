import 'dart:math';

import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:debounce_throttle/debounce_throttle.dart';

import 'bot.dart';
import 'package:weather/src/modules/chat_manager.dart' show ChatPlatform;
import 'package:weather/src/modules/accordion_poll.dart' show AccordionVoteOption, AccordionVoteResults;
import 'package:weather/src/modules/commands_manager.dart';

// TODO: maybe remove all the logic from Bot class and put it to the modules itself like invokeIncrease, invokeDecrease, invokeAdd, etc.
// this methods would accept MessageEvent and the Bot class will have something like sendMessage(reputation.invokeIncrease());n
// TODO: maybe try to extract commands to a separate class and make setupCommands a part of abstract class
// TODO: make permissions identical between different platforms
class TelegramBot extends Bot<TeleDartMessage> {
  late TeleDart bot;
  late Telegram telegram;
  late Debouncer<TeleDartInlineQuery?> debouncer = Debouncer(Duration(seconds: 1), initialValue: null);

  TelegramBot(
      {required super.botToken,
      required super.adminId,
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

    _subscribeToPanoramaNews();
    _subscribeToWeather();
    _subscribeToUsersUpdate();

    bot.start();

    print('Telegram bot has been started!');
  }

  @override
  Future<void> sendMessage(String chatId, String message) async {
    if (message.isEmpty) {
      await telegram.sendMessage(chatId, sm.get('general.something_went_wrong'));

      return;
    }

    await telegram.sendMessage(chatId, message);
  }

  // // TODO: make a map in Bot class like {'addcity': addCity} and use it instead of manually adding all the commands
  // @override
  // void setupCommands() {
  //   bot.onCommand('addcity').listen(
  //       (event) => cm.userCommand(_mapToMessageEventWithParameters(event), onSuccess: addWeatherCity, onFailure: sendNoAccessMessage));
  //   bot.onCommand('removecity').listen(
  //       (event) => cm.userCommand(_mapToMessageEventWithParameters(event), onSuccess: removeWeatherCity, onFailure: sendNoAccessMessage));
  //   bot.onCommand('watchlist').listen(
  //       (event) => cm.userCommand(_mapToGeneralMessageEvent(event), onSuccess: getWeatherWatchlist, onFailure: sendNoAccessMessage));
  //   bot.onCommand('getweather').listen(
  //       (event) => cm.userCommand(_mapToMessageEventWithParameters(event), onSuccess: getWeatherForCity, onFailure: sendNoAccessMessage));
  //   bot.onCommand('setnotificationhour').listen((event) => cm.moderatorCommand(_mapToMessageEventWithParameters(event),
  //       onSuccess: setWeatherNotificationHour, onFailure: sendNoAccessMessage));
  //   bot.onCommand('write').listen(
  //       (event) => cm.moderatorCommand(_mapToMessageEventWithParameters(event), onSuccess: writeToChat, onFailure: sendNoAccessMessage));
  //   bot
  //       .onCommand('updatemessage')
  //       .listen((event) => cm.adminCommand(_mapToGeneralMessageEvent(event), onSuccess: postUpdateMessage, onFailure: sendNoAccessMessage));
  //   bot
  //       .onCommand('sendnews')
  //       .listen((event) => cm.userCommand(_mapToGeneralMessageEvent(event), onSuccess: sendNewsToChat, onFailure: sendNoAccessMessage));
  //   bot
  //       .onCommand('sendjoke')
  //       .listen((event) => cm.userCommand(_mapToGeneralMessageEvent(event), onSuccess: sendJokeToChat, onFailure: sendNoAccessMessage));
  //   bot.onCommand('sendrealmusic').listen(
  //       (event) => cm.userCommand(_mapToMessageEventWithParameters(event), onSuccess: sendRealMusicToChat, onFailure: sendNoAccessMessage));
  //   bot.onCommand('increp').listen(
  //       (event) => cm.userCommand(_mapToEventWithOtherUserIds(event), onSuccess: increaseReputation, onFailure: sendNoAccessMessage));
  //   bot.onCommand('decrep').listen(
  //       (event) => cm.userCommand(_mapToEventWithOtherUserIds(event), onSuccess: decreaseReputation, onFailure: sendNoAccessMessage));
  //   bot
  //       .onCommand('replist')
  //       .listen((event) => cm.userCommand(_mapToGeneralMessageEvent(event), onSuccess: sendReputationList, onFailure: sendNoAccessMessage));
  //   bot.onCommand('searchsong').listen(
  //       (event) => cm.userCommand(_mapToMessageEventWithParameters(event), onSuccess: searchYoutubeTrack, onFailure: sendNoAccessMessage));
  //   bot
  //       .onCommand('na')
  //       .listen((event) => cm.userCommand(_mapToGeneralMessageEvent(event), onSuccess: healthCheck, onFailure: sendNoAccessMessage));
  //   bot.onCommand('accordion').listen((event) => cm.userCommand(_mapToGeneralMessageEvent(event),
  //       onSuccessCustom: () => _startTelegramAccordionPoll(event), onFailure: sendNoAccessMessage));
  //   bot.onCommand('ask').listen(
  //       (event) => cm.userCommand(_mapToMessageEventWithParameters(event), onSuccess: askConversator, onFailure: sendNoAccessMessage));
  //   bot
  //       .onCommand('adduser')
  //       .listen((event) => cm.moderatorCommand(_mapToEventWithOtherUserIds(event), onSuccess: addUser, onFailure: sendNoAccessMessage));
  //   bot
  //       .onCommand('removeuser')
  //       .listen((event) => cm.moderatorCommand(_mapToEventWithOtherUserIds(event), onSuccess: removeUser, onFailure: sendNoAccessMessage));
  //   bot
  //       .onCommand('initialize')
  //       .listen((event) => cm.adminCommand(_mapToGeneralMessageEvent(event), onSuccess: initializeChat, onFailure: sendNoAccessMessage));
  //   bot.onCommand('createreputation').listen(
  //       (event) => cm.adminCommand(_mapToEventWithOtherUserIds(event), onSuccess: createReputation, onFailure: sendNoAccessMessage));
  //   bot
  //       .onCommand('createweather')
  //       .listen((event) => cm.adminCommand(_mapToGeneralMessageEvent(event), onSuccess: createWeather, onFailure: sendNoAccessMessage));
  //
  //   var bullyTagUserRegexp = RegExp(sm.get('general.bully_tag_user_regexp'), caseSensitive: false);
  //   bot.onMessage(keyword: bullyTagUserRegexp).listen((event) => _bullyTagUser(event));
  //
  //   bot.onInlineQuery().listen((query) {
  //     debouncer.value = query;
  //   });
  //   debouncer.values.listen((query) {
  //     _searchYoutubeTrackInline(query as TeleDartInlineQuery);
  //   });
  // }

  @override
  void setupCommand(String command, CommandsWrapper cmCommandWrapper, MessageEventMapper<TeleDartMessage> mapToMessageEvent,
      OnSuccessCallback onSuccessCallback,
      [String? description]) {
    bot
        .onCommand(command)
        .listen((event) => cmCommandWrapper(mapToMessageEvent(event), onSuccess: onSuccessCallback, onFailure: sendNoAccessMessage));
  }

  // @override
  // void setupCommand(String command, CommandsWrapper cmCommandWrapper, EventMapper eventMapper, OnSuccessCallback onSuccess) {
  //   bot.onCommand(command).listen((event) => cmCommandWrapper(eventMapper(event), onSuccess: onSuccess, onFailure: sendNoAccessMessage));
  // }

  @override
  MessageEvent mapToGeneralMessageEvent(TeleDartMessage event, [List? params]) {
    return MessageEvent(
        platform: ChatPlatform.telegram,
        chatId: event.chat.id.toString(),
        userId: event.from?.id.toString() ?? '',
        isBot: event.replyToMessage?.from?.isBot ?? false,
        message: event.text?.split(' ').sublist(1).join(' ') ?? '',
        otherUserIds: [],
        parameters: [],
        rawMessage: event);
  }

  @override
  MessageEvent mapToMessageEventWithParameters(TeleDartMessage event, [List? otherParameters]) {
    List<String> parameters = event.text?.split(' ').sublist(1).toList() ?? [];

    return mapToGeneralMessageEvent(event)..parameters.addAll(parameters);
  }

  @override
  MessageEvent mapToMessageEventWithOtherUserIds(TeleDartMessage event, [List? otherUserIds]) {
    return mapToGeneralMessageEvent(event)..otherUserIds.add(event.replyToMessage?.from?.id.toString() ?? '');
  }

  void _subscribeToPanoramaNews() {
    var panoramaStream = panoramaNews.panoramaStream;

    panoramaStream.listen((event) async {
      var allChats = await chatManager.getAllChatIds(ChatPlatform.telegram);

      allChats.forEach((chatId) {
        var fakeEvent = MessageEvent(
            platform: ChatPlatform.telegram,
            chatId: chatId,
            userId: '',
            isBot: false,
            message: '',
            otherUserIds: [],
            parameters: [],
            rawMessage: '');

        sendNewsToChat(fakeEvent);
      });
    });
  }

  void _subscribeToWeather() async {
    var telegramChats = await chatManager.getAllChatIds(ChatPlatform.telegram);
    var weatherStream = weatherManager.weatherStream;

    weatherStream.listen((weatherData) {
      var message = '';

      weatherData.weatherData.forEach((weatherData) {
        message += 'In city: ${weatherData.city} the temperature is ${weatherData.temp}\n\n';
      });

      if (telegramChats.contains(weatherData.chatId)) {
        sendMessage(weatherData.chatId, message);
      }
    });
  }

  void _subscribeToUsersUpdate() {
    var userManagerStream = userManager.userManagerStream;

    userManagerStream.listen((_) {
      print('TODO: update users premium status');
    });
  }

  void _startTelegramAccordionPoll(TeleDartMessage message) async {
    var chatId = message.chat.id.toString();
    const pollTime = 15;
    var pollOptions = [sm.get('accordion.options.yes'), sm.get('accordion.options.no'), sm.get('accordion.options.maybe')];

    if (accordionPoll.isVoteActive) {
      await sendMessage(chatId, sm.get('accordion.other.accordion_vote_in_progress'));

      return;
    }

    var votedMessageAuthor = message.replyToMessage?.from;

    if (votedMessageAuthor == null) {
      await sendMessage(chatId, sm.get('accordion.other.message_not_chosen'));

      return;
    } else if (votedMessageAuthor.isBot) {
      await sendMessage(chatId, sm.get('accordion.other.bot_vote_attempt'));

      return;
    }

    accordionPoll.startPoll(votedMessageAuthor.id.toString());

    var createdPoll = await telegram.sendPoll(
      chatId,
      sm.get('accordion.other.title'),
      pollOptions,
      explanation: sm.get('accordion.other.explanation'),
      type: 'quiz',
      correctOptionId: Random().nextInt(pollOptions.length),
      openPeriod: pollTime,
    );

    var pollSubscription = bot.onPoll().listen((poll) {
      if (createdPoll.poll?.id != poll.id) {
        print('Wrong poll');

        return;
      }

      var currentPollResults = {
        AccordionVoteOption.yes: poll.options[0].voterCount,
        AccordionVoteOption.no: poll.options[1].voterCount,
        AccordionVoteOption.maybe: poll.options[2].voterCount
      };

      accordionPoll.voteResult = currentPollResults;
    });

    await Future.delayed(Duration(seconds: pollTime));

    var voteResult = accordionPoll.endVoteAndGetResults();

    switch (voteResult) {
      case AccordionVoteResults.yes:
        await sendMessage(chatId, sm.get('accordion.results.yes'));
        break;
      case AccordionVoteResults.no:
        await sendMessage(chatId, sm.get('accordion.results.no'));
        break;
      case AccordionVoteResults.maybe:
        await sendMessage(chatId, sm.get('accordion.results.maybe'));
        break;
      case AccordionVoteResults.noResults:
        await sendMessage(chatId, sm.get('accordion.results.noResults'));
        break;
    }

    await pollSubscription.cancel();
  }

  void _bullyTagUser(TeleDartMessage message) async {
    // just an original feature of this bot that will stay here forever
    var denisId = '354903232';
    var messageAuthorId = message.from?.id.toString();
    var chatId = message.chat.id.toString();

    if (messageAuthorId == adminId) {
      await sendMessage(chatId, '@daimonil');
    } else if (messageAuthorId == denisId) {
      await sendMessage(chatId, '@dmbaranov_io');
    }
  }

  Future<void> _searchYoutubeTrackInline(TeleDartInlineQuery query) async {
    var searchResults = await youtube.getYoutubeSearchResults(query.query);
    List items = searchResults['items'];
    var inlineQueryResult = [];

    items.forEach((searchResult) {
      var videoId = searchResult['id']['videoId'];
      var videoData = searchResult['snippet'];
      var videoUrl = 'https://www.youtube.com/watch?v=$videoId';

      inlineQueryResult.add(InlineQueryResultVideo(
          id: videoId,
          title: videoData['title'],
          thumbUrl: videoData['thumbnails']['high']['url'],
          mimeType: 'video/mp4',
          videoDuration: 600,
          videoUrl: videoUrl,
          inputMessageContent: InputTextMessageContent(messageText: videoUrl, disableWebPagePreview: false)));
    });

    await bot.answerInlineQuery(query.id, [...inlineQueryResult], cacheTime: 10);
  }
}
