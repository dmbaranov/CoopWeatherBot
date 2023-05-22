import 'dart:math';
import 'dart:io' as io;

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
class TelegramBot extends Bot<TeleDartMessage, Message> {
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

    setupCommands();
    setupPlatformSpecificCommands();

    _subscribeToPanoramaNews();
    _subscribeToWeather();
    _subscribeToUsersUpdate();

    bot.start();

    print('Telegram bot has been started!');
  }

  @override
  Future<Message> sendMessage(String chatId, String message) async {
    if (message.isEmpty) {
      return telegram.sendMessage(chatId, chatManager.getText(chatId, 'general.something_went_wrong'));
    }

    return telegram.sendMessage(chatId, message);
  }

  @override
  void setupCommand(Command<TeleDartMessage> command) {
    var messageMapper = _getEventMapper(command);

    bot
        .onCommand(command.command)
        .listen((event) => command.wrapper(messageMapper(event), onSuccess: command.successCallback, onFailure: sendNoAccessMessage));
  }

  @override
  void setupPlatformSpecificCommands() async {
    bot.onCommand('accordion').listen((event) => cm.userCommand(mapToGeneralMessageEvent(event),
        onSuccessCustom: () => _startTelegramAccordionPoll(event), onFailure: sendNoAccessMessage));

    var bullyTagUserRegexpRaw = await io.File('assets/misc/bully_tag_user.txt').readAsString();
    var bullyTagUserRegexp = bullyTagUserRegexpRaw.replaceAll('\n', '');

    bot.onMessage(keyword: RegExp(bullyTagUserRegexp, caseSensitive: false)).listen((event) => _bullyTagUser(event));
    bot.onInlineQuery().listen((query) {
      debouncer.value = query;
    });
    debouncer.values.listen((query) {
      _searchYoutubeTrackInline(query as TeleDartInlineQuery);
    });
  }

  @override
  MessageEvent mapToGeneralMessageEvent(TeleDartMessage event) {
    return MessageEvent(
        platform: ChatPlatform.telegram,
        chatId: event.chat.id.toString(),
        userId: event.from?.id.toString() ?? '',
        isBot: event.replyToMessage?.from?.isBot ?? false,
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
    return mapToGeneralMessageEvent(event)
      ..otherUserIds.add(event.replyToMessage?.from?.id.toString() ?? '')
      ..parameters.addAll(_getUserInfo(event));
  }

  @override
  MessageEvent mapToConversatorMessageEvent(TeleDartMessage event, [List? otherParameters]) {
    var currentMessageId = event.messageId.toString();
    var parentMessageId = event.replyToMessage?.messageId.toString() ?? currentMessageId;
    var message = event.text?.split(' ').sublist(1).join(' ') ?? '';

    return mapToGeneralMessageEvent(event)..parameters.addAll([parentMessageId, currentMessageId, message]);
  }

  @override
  String getMessageId(Message message) {
    return message.messageId.toString();
  }

  Function _getEventMapper(Command command) {
    if (command.withParameters) {
      return mapToMessageEventWithParameters;
    } else if (command.withOtherUserIds) {
      return mapToMessageEventWithOtherUserIds;
    } else if (command.conversatorCommand) {
      return mapToConversatorMessageEvent;
    }

    return mapToGeneralMessageEvent;
  }

  void _subscribeToPanoramaNews() {
    var panoramaStream = panoramaNews.panoramaStream;

    panoramaStream.listen((event) async {
      var allChats = await chatManager.getAllChatIdsForPlatform(ChatPlatform.telegram);

      allChats.forEach((chatId) {
        var fakeEvent = MessageEvent(
            platform: ChatPlatform.telegram, chatId: chatId, userId: '', isBot: false, otherUserIds: [], parameters: [], rawMessage: '');

        sendNewsToChat(fakeEvent);
      });
    });
  }

  void _subscribeToWeather() async {
    var telegramChats = await chatManager.getAllChatIdsForPlatform(ChatPlatform.telegram);
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
    const pollTime = 180;
    var pollOptions = [
      chatManager.getText(chatId, 'accordion.options.yes'),
      chatManager.getText(chatId, 'accordion.options.no'),
      chatManager.getText(chatId, 'accordion.options.maybe')
    ];

    if (accordionPoll.isVoteActive) {
      await sendMessage(chatId, chatManager.getText(chatId, 'accordion.other.accordion_vote_in_progress'));

      return;
    }

    var votedMessageAuthor = message.replyToMessage?.from;

    if (votedMessageAuthor == null) {
      await sendMessage(chatId, chatManager.getText(chatId, 'accordion.other.message_not_chosen'));

      return;
    } else if (votedMessageAuthor.isBot) {
      await sendMessage(chatId, chatManager.getText(chatId, 'accordion.other.bot_vote_attempt'));

      return;
    }

    accordionPoll.startPoll(votedMessageAuthor.id.toString());

    var createdPoll = await telegram.sendPoll(
      chatId,
      chatManager.getText(chatId, 'accordion.other.title'),
      pollOptions,
      explanation: chatManager.getText(chatId, 'accordion.other.explanation'),
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
        await sendMessage(chatId, chatManager.getText(chatId, 'accordion.results.yes'));
        break;
      case AccordionVoteResults.no:
        await sendMessage(chatId, chatManager.getText(chatId, 'accordion.results.no'));
        break;
      case AccordionVoteResults.maybe:
        await sendMessage(chatId, chatManager.getText(chatId, 'accordion.results.maybe'));
        break;
      case AccordionVoteResults.noResults:
        await sendMessage(chatId, chatManager.getText(chatId, 'accordion.results.noResults'));
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

  List<String> _getUserInfo(TeleDartMessage message) {
    var fullUsername = '';
    var repliedUser = message.replyToMessage?.from;

    if (repliedUser == null) {
      return [];
    }

    fullUsername += repliedUser.firstName;

    if (repliedUser.username != null) {
      fullUsername += ' <${repliedUser.username}> ';
    }

    fullUsername += repliedUser.lastName ?? '';

    return [fullUsername, repliedUser.isPremium?.toString() ?? 'false'];
  }
}
