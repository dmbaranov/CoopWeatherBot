import 'dart:async';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/accordion_poll.dart';

import 'package:weather/src/platform/telegram_platform.dart';
import 'package:weather/src/platform/discord_platform.dart';

import 'package:weather/src/modules/user/user.dart';
import 'package:weather/src/modules/chat/chat.dart';

abstract class Platform<T> {
  late ChatPlatform chatPlatform;

  factory Platform({required Chat chat, required User user, required ChatPlatform chatPlatform}) {
    switch (chatPlatform) {
      case ChatPlatform.telegram:
        return TelegramPlatform(chatPlatform: ChatPlatform.telegram, chat: chat, user: user);
      case ChatPlatform.discord:
        return DiscordPlatform(chatPlatform: ChatPlatform.discord, chat: chat, user: user);
      default:
        throw Exception('Platform $chatPlatform is not supported');
    }
  }

  Future<void> initialize();

  Future<void> postStart();

  MessageEvent transformPlatformMessageToGeneralMessageEvent(T message);

  MessageEvent transformPlatformMessageToMessageEventWithParameters(T message, [List? otherParameters]);

  MessageEvent transformPlatformMessageToMessageEventWithOtherUserIds(T message, [List? otherUserIds]);

  MessageEvent transformPlatformMessageToConversatorMessageEvent(T message, [List<String>? otherParameters]);

  void setupCommand(BotCommand command);

  Future sendMessage(String chatId, {String? message, String? translation});

  Future sendNoAccessMessage(MessageEvent event);

  Future sendErrorMessage(MessageEvent event);

  Future<bool> getUserPremiumStatus(String chatId, String userId);

  String getMessageId(T message);

  Future<StreamController<Map<AccordionVoteOption, int>>> startAccordionPoll(String chatId, List<String> pollOptions, int pollTime);
}
