import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/bot_command.dart';

import 'package:weather/src/modules/commands_manager.dart';
import 'package:weather/src/modules/chat_manager.dart';
import 'package:weather/src/modules/youtube.dart';
import 'package:weather/src/modules/user_manager.dart';

import 'package:weather/src/platform/telegram_platform.dart';
import 'package:weather/src/platform/discord_platform.dart';

abstract class Platform<T> {
  late ChatPlatform chatPlatform;

  factory Platform(
      {required ChatManager chatManager,
      required UserManager userManager,
      required String token,
      required String adminId,
      required ChatPlatform chatPlatform}) {
    switch (chatPlatform) {
      case ChatPlatform.telegram:
        return TelegramPlatform(chatPlatform: ChatPlatform.telegram, token: token, adminId: adminId, chatManager: chatManager);
      case ChatPlatform.discord:
        return DiscordPlatform(
            chatPlatform: ChatPlatform.discord, token: token, adminId: adminId, chatManager: chatManager, userManager: userManager);
      default:
        throw Exception('Platform $chatPlatform is not supported');
    }
  }

  Future<void> initializePlatform();

  void setupPlatformSpecificCommands(CommandsManager cm);

  Future<void> postStart();

  MessageEvent transformPlatformMessageToGeneralMessageEvent(T message);

  MessageEvent transformPlatformMessageToMessageEventWithParameters(T message, [List? otherParameters]);

  MessageEvent transformPlatformMessageToMessageEventWithOtherUserIds(T message, [List? otherUserIds]);

  MessageEvent transformPlatformMessageToConversatorMessageEvent(T message, [List<String>? otherParameters]);

  void setupCommand(Command command);

  Future sendMessage(String chatId, {String? message, String? translation});

  Future sendNoAccessMessage(MessageEvent event);

  Future sendErrorMessage(MessageEvent event);

  Future<bool> getUserPremiumStatus(String chatId, String userId);

  String getMessageId(T message);
}
