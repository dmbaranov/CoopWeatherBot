import 'dart:async';
import 'dart:io' as io;
import 'dart:math';

import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:teledart/model.dart' show TeleDartMessage, TeleDartInlineQuery, Message;
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/access.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/modules/modules_mediator.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/poll.dart';
import 'package:weather/src/utils/logger.dart';
import 'telegram_module.dart';

class TelegramPlatform<T extends TeleDartMessage> implements Platform<T> {
  @override
  late final ChatPlatform chatPlatform;
  final ModulesMediator modulesMediator;
  final Config _config;
  final Access _access;
  final Logger _logger;
  final Swearwords _sw;
  final Debouncer<TeleDartInlineQuery?> _debouncer = Debouncer(Duration(seconds: 1), initialValue: null);

  late final TeleDart _bot;
  late final Telegram _telegram;
  late final TelegramModule _telegramModule;

  TelegramPlatform({required this.chatPlatform, required this.modulesMediator})
      : _config = getIt<Config>(),
        _access = getIt<Access>(),
        _logger = getIt<Logger>(),
        _sw = getIt<Swearwords>();

  @override
  void initialize() {
    _telegram = Telegram(_config.token);
    _bot = TeleDart(_config.token, Event(_config.botName), fetcher: LongPolling(_telegram, limit: 100, timeout: 50));
    _telegramModule = TelegramModule(bot: _bot, telegram: _telegram, platform: this, modulesMediator: modulesMediator)..initialize();

    _setupPlatformSpecificCommands();
    _bot.start();

    _logger.i('Telegram platform has been started!');
  }

  @override
  Future<void> postStart() async {
    _logger.i('No post-start script for Telegram');
  }

  @override
  MessageEvent transformPlatformMessageToGeneralMessageEvent(TeleDartMessage message) {
    return MessageEvent(
        platform: chatPlatform,
        chatId: message.chat.id.toString(),
        userId: message.from?.id.toString() ?? '',
        isBot: message.replyToMessage?.from?.isBot ?? false,
        parameters: [],
        rawMessage: message);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithParameters(TeleDartMessage message, [List? otherParameters]) {
    List<String> parameters = message.text?.split(' ').sublist(1).toList() ?? [];

    return transformPlatformMessageToGeneralMessageEvent(message)..parameters.addAll(parameters);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithOtherUser(TeleDartMessage event,
      [({String id, String name, bool isPremium})? otherUser]) {
    return transformPlatformMessageToGeneralMessageEvent(event)..otherUser = _getOtherUserInfo(event);
  }

  @override
  MessageEvent transformPlatformMessageToConversatorMessageEvent(TeleDartMessage event, [List<String>? otherParameters]) {
    var currentMessageId = event.messageId.toString();
    var parentMessageId = event.replyToMessage?.messageId.toString() ?? currentMessageId;
    var message = event.text?.split(' ').sublist(1).join(' ') ?? '';

    return transformPlatformMessageToGeneralMessageEvent(event)..parameters.addAll([parentMessageId, currentMessageId, message]);
  }

  @override
  void setupCommand(BotCommand command) {
    var eventMapper = _getEventMapper(command);

    _bot.onCommand(command.command).listen((event) {
      if (event.text?.startsWith('/') == true) {
        _access.execute(
            event: eventMapper(event),
            command: command.command,
            accessLevel: command.accessLevel,
            onSuccess: command.onSuccess,
            onFailure: sendNoAccessMessage);
      }
    });
  }

  @override
  Future<Message> sendMessage(String chatId, {String? message, String? translation}) async {
    if (message != null) {
      return _telegram.sendMessage(chatId, message);
    } else if (translation != null) {
      return _telegram.sendMessage(chatId, _sw.getText(chatId, translation));
    }

    return _telegram.sendMessage(chatId, _sw.getText(chatId, 'something_went_wrong'));
  }

  @override
  Future<void> sendNoAccessMessage(MessageEvent event) async {
    var chatId = event.chatId;

    await sendMessage(chatId, translation: 'general.no_access');
  }

  @override
  Future<void> sendErrorMessage(MessageEvent event) async {
    await sendMessage(event.chatId, translation: 'general.something_went_wrong');
  }

  @override
  Future<bool> getUserPremiumStatus(String chatId, String userId) async {
    var telegramUser = await _telegram.getChatMember(chatId, int.parse(userId));

    return telegramUser.user.isPremium ?? false;
  }

  @override
  String getMessageId(Message message) {
    return message.messageId.toString();
  }

  void _setupPlatformSpecificCommands() async {
    var bullyTagUserRegexpRaw = await io.File('assets/misc/bully_tag_user.txt').readAsString();
    var bullyTagUserRegexp = bullyTagUserRegexpRaw.replaceAll('\n', '');

    _bot.onMessage(keyword: RegExp(bullyTagUserRegexp, caseSensitive: false)).listen((event) => _telegramModule.bullyTagUser(event));
    _bot.onInlineQuery().listen((query) {
      _debouncer.value = query;
    });
    _debouncer.values.listen((query) {
      _telegramModule.searchYoutubeTrackInline(query as TeleDartInlineQuery);
    });
  }

  @override
  Future<String> concludePoll(String chatId, Poll poll) async {
    await _telegram.sendPoll(chatId, poll.title, poll.options,
        explanation: poll.description,
        type: 'quiz',
        correctOptionId: Random().nextInt(poll.options.length),
        openPeriod: poll.duration.inSeconds);

    var pollStream = _bot.onPoll().listen((event) {
      event.options.forEach((option) {
        poll.updatePollOptionCount(option.text, option.voterCount);
      });
    });

    await Future.delayed(poll.duration);

    pollStream.cancel();

    return poll.result;
  }

  ({String id, String name, bool isPremium})? _getOtherUserInfo(TeleDartMessage message) {
    var fullUsername = '';
    var repliedUser = message.replyToMessage?.from;

    if (repliedUser == null) {
      return null;
    }

    fullUsername += repliedUser.firstName;

    if (repliedUser.username != null) {
      fullUsername += ' <${repliedUser.username}> ';
    }

    fullUsername += repliedUser.lastName ?? '';

    return (id: repliedUser.id.toString(), name: fullUsername, isPremium: repliedUser.isPremium ?? false);
  }

  Function _getEventMapper(BotCommand command) {
    if (command.withParameters) {
      return transformPlatformMessageToMessageEventWithParameters;
    } else if (command.withOtherUser) {
      return transformPlatformMessageToMessageEventWithOtherUser;
    } else if (command.conversatorCommand) {
      return transformPlatformMessageToConversatorMessageEvent;
    }

    return transformPlatformMessageToGeneralMessageEvent;
  }
}
