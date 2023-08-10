import 'dart:math';
import 'dart:io' as io;

import 'package:collection/collection.dart';
import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:debounce_throttle/debounce_throttle.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/command.dart';

import 'package:weather/src/modules/commands_manager.dart';
import 'package:weather/src/modules/chat_manager.dart';
import 'package:weather/src/modules/youtube.dart';
import 'package:weather/src/modules/accordion_poll.dart';

import 'package:weather/src/platform/platform.dart';

class TelegramPlatform<T extends TeleDartMessage> implements Platform<T> {
  final String token;
  final String adminId;
  final ChatManager chatManager;
  final Youtube youtube;

  late TeleDart _bot;
  late Telegram _telegram;
  late Debouncer<TeleDartInlineQuery?> _debouncer = Debouncer(Duration(seconds: 1), initialValue: null);
  late AccordionPoll _accordionPoll;

  TelegramPlatform({required this.token, required this.adminId, required this.chatManager, required this.youtube});

  @override
  Future<void> initializePlatform() async {
    var botName = (await Telegram(token).getMe()).username;

    _telegram = Telegram(token);
    _bot = TeleDart(token, Event(botName!), fetcher: LongPolling(Telegram(token), limit: 100, timeout: 50));
    _accordionPoll = AccordionPoll();

    _bot.start();

    print('Telegram platform has been started!');
  }

  @override
  void setupPlatformSpecificCommands(CommandsManager cm) async {
    setupCommand(Command(
        command: 'accordion',
        description: 'Start vote for the freshness of the content',
        wrapper: cm.userCommand,
        withOtherUserIds: true,
        successCallback: _startTelegramAccordionPoll));

    var bullyTagUserRegexpRaw = await io.File('assets/misc/bully_tag_user.txt').readAsString();
    var bullyTagUserRegexp = bullyTagUserRegexpRaw.replaceAll('\n', '');

    _bot.onMessage(keyword: RegExp(bullyTagUserRegexp, caseSensitive: false)).listen((event) => _bullyTagUser(event));
    _bot.onInlineQuery().listen((query) {
      _debouncer.value = query;
    });
    _debouncer.values.listen((query) {
      _searchYoutubeTrackInline(query as TeleDartInlineQuery);
    });
  }

  @override
  Future<void> postStart() async {
    print('No post-start script for Telegram');
  }

  @override
  MessageEvent transformPlatformMessageToGeneralMessageEvent(TeleDartMessage message) {
    return MessageEvent(
        platform: ChatPlatform.telegram,
        chatId: message.chat.id.toString(),
        userId: message.from?.id.toString() ?? '',
        isBot: message.replyToMessage?.from?.isBot ?? false,
        otherUserIds: [],
        parameters: [],
        rawMessage: message);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithParameters(TeleDartMessage message, [List? otherParameters]) {
    List<String> parameters = message.text?.split(' ').sublist(1).toList() ?? [];

    return transformPlatformMessageToGeneralMessageEvent(message)..parameters.addAll(parameters);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithOtherUserIds(TeleDartMessage event, [List? otherUserIds]) {
    var otherUserId = [event.replyToMessage?.from?.id.toString()].whereNotNull();

    return transformPlatformMessageToGeneralMessageEvent(event)
      ..otherUserIds.addAll(otherUserId)
      ..parameters.addAll(_getUserInfo(event));
  }

  @override
  MessageEvent transformPlatformMessageToConversatorMessageEvent(TeleDartMessage event, [List<String>? otherParameters]) {
    var currentMessageId = event.messageId.toString();
    var parentMessageId = event.replyToMessage?.messageId.toString() ?? currentMessageId;
    var message = event.text?.split(' ').sublist(1).join(' ') ?? '';

    return transformPlatformMessageToGeneralMessageEvent(event)..parameters.addAll([parentMessageId, currentMessageId, message]);
  }

  @override
  void setupCommand(Command command) {
    var eventMapper = _getEventMapper(command);

    _bot
        .onCommand(command.command)
        .listen((event) => command.wrapper(eventMapper(event), onSuccess: command.successCallback, onFailure: sendNoAccessMessage));
  }

  @override
  Future<Message> sendMessage(String chatId, String message) async {
    if (message.isEmpty) {
      return _telegram.sendMessage(chatId, 'something_went_wrong');
    }

    return _telegram.sendMessage(chatId, message);
  }

  @override
  Future<void> sendNoAccessMessage(MessageEvent event) async {
    await sendMessage(event.chatId, chatManager.getText(event.chatId, 'general.no_access'));
  }

  @override
  Future<void> sendErrorMessage(MessageEvent event) async {
    await sendMessage(event.chatId, chatManager.getText(event.chatId, 'general.something_went_wrong'));
  }

  @override
  Future<bool> getUserPremiumStatus(String chatId, String userId) async {
    var telegramUser = await _telegram.getChatMember(chatId, int.parse(userId));

    return telegramUser.user.isPremium ?? false;
  }

  @override
  String getMessageId(TeleDartMessage message) {
    return message.messageId.toString();
  }

  void _startTelegramAccordionPoll(MessageEvent event) async {
    var chatId = event.chatId;
    const pollTime = 180;
    var pollOptions = [
      chatManager.getText(chatId, 'accordion.options.yes'),
      chatManager.getText(chatId, 'accordion.options.no'),
      chatManager.getText(chatId, 'accordion.options.maybe')
    ];

    if (_accordionPoll.isVoteActive) {
      await sendMessage(chatId, chatManager.getText(chatId, 'accordion.other.accordion_vote_in_progress'));

      return;
    } else if (event.otherUserIds.isEmpty) {
      await sendMessage(chatId, chatManager.getText(chatId, 'accordion.other.message_not_chosen'));

      return;
    } else if (event.isBot) {
      await sendMessage(chatId, chatManager.getText(chatId, 'accordion.other.bot_vote_attempt'));

      return;
    }

    _accordionPoll.startPoll(event.otherUserIds[0]);

    var createdPoll = await _telegram.sendPoll(
      chatId,
      chatManager.getText(chatId, 'accordion.other.title'),
      pollOptions,
      explanation: chatManager.getText(chatId, 'accordion.other.explanation'),
      type: 'quiz',
      correctOptionId: Random().nextInt(pollOptions.length),
      openPeriod: pollTime,
    );

    var pollSubscription = _bot.onPoll().listen((poll) {
      if (createdPoll.poll?.id != poll.id) {
        print('Wrong poll');

        return;
      }

      var currentPollResults = {
        AccordionVoteOption.yes: poll.options[0].voterCount,
        AccordionVoteOption.no: poll.options[1].voterCount,
        AccordionVoteOption.maybe: poll.options[2].voterCount
      };

      _accordionPoll.voteResult = currentPollResults;
    });

    await Future.delayed(Duration(seconds: pollTime));

    var voteResult = _accordionPoll.endVoteAndGetResults();

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

  Function _getEventMapper(Command command) {
    if (command.withParameters) {
      return transformPlatformMessageToMessageEventWithParameters;
    } else if (command.withOtherUserIds) {
      return transformPlatformMessageToMessageEventWithOtherUserIds;
    } else if (command.conversatorCommand) {
      return transformPlatformMessageToConversatorMessageEvent;
    }

    return transformPlatformMessageToGeneralMessageEvent;
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

    await _bot.answerInlineQuery(query.id, [...inlineQueryResult], cacheTime: 10);
  }
}
