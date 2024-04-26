import 'dart:async';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/accordion_vote_option.dart';

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
      default:
        throw Exception('Platform $chatPlatform is not supported');
    }
  }

  void initialize();

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
