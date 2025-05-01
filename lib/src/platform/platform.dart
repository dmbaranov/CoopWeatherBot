import 'dart:async';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/poll.dart';

import 'package:weather/src/platform/telegram/telegram_platform.dart';
import 'package:weather/src/platform/discord/discord_platform.dart';

import 'package:weather/src/modules/modules_mediator.dart';

abstract class Platform<T> {
  late final ChatPlatform chatPlatform;

  factory Platform({required ChatPlatform chatPlatform, required ModulesMediator modulesMediator}) {
    switch (chatPlatform) {
      case ChatPlatform.telegram:
        return TelegramPlatform(chatPlatform: ChatPlatform.telegram, modulesMediator: modulesMediator);
      case ChatPlatform.discord:
        return DiscordPlatform(chatPlatform: ChatPlatform.discord, modulesMediator: modulesMediator);
    }
  }

  void initialize();

  Future<void> postStart();

  MessageEvent transformPlatformMessageToGeneralMessageEvent(T message);

  MessageEvent transformPlatformMessageToMessageEventWithParameters(T message, [List? otherParameters]);

  MessageEvent transformPlatformMessageToMessageEventWithOtherUser(T message,
      [({String id, String name, bool isPremium, bool isBot})? otherUser]);

  MessageEvent transformPlatformMessageToConversatorMessageEvent(T message, [List<String>? otherParameters]);

  void setupCommand(BotCommand command);

  Future sendMessage(String chatId, {String? message, String? translation});

  Future sendNoAccessMessage(MessageEvent event);

  Future sendErrorMessage(MessageEvent event);

  Future<bool> getUserPremiumStatus(String chatId, String userId);

  String getMessageId(T message);

  Future<String> concludePoll(String chatID, Poll poll);
}
