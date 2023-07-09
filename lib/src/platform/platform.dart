import 'package:meta/meta.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/command.dart';
import 'package:weather/src/modules/commands_manager.dart';

import 'package:weather/src/platform/telegram/telegram_platform.dart';
import 'package:weather/src/platform/discord/discord_platform.dart';

abstract class Platform<T> {
  factory Platform({required ChatPlatform chatPlatform, required String token}) {
    switch (chatPlatform) {
      case ChatPlatform.telegram:
        return TelegramPlatform(token: token);
      case ChatPlatform.discord:
        return DiscordPlatform(token: token);
      default:
        throw Exception('Platform $chatPlatform is not supported');
    }
  }

  Future<void> initializePlatform();

  void setupPlatformSpecificCommands(CommandsManager cm);

  Future<void> postStart();

  @protected
  MessageEvent transformPlatformMessageToGeneralMessageEvent(T message);

  @protected
  MessageEvent transformPlatformMessageToMessageEventWithParameters(T message, [List? otherParameters]);

  @protected
  MessageEvent transformPlatformMessageToMessageEventWithOtherUserIds(T message, [List? otherUserIds]);

  @protected
  MessageEvent transformPlatformMessageToConversatorMessageEvent(T message, [List<String>? otherParameters]);

  @protected
  void setupCommand(Command command);

  @protected
  Future sendMessage(String chatId, String message);

  @protected
  Future<bool> getUserPremiumStatus(String chatId, String userId);

  @protected
  String getMessageId(T message);
}
