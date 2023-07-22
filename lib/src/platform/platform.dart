import 'package:meta/meta.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/command.dart';

import 'package:weather/src/modules/commands_manager.dart';
import 'package:weather/src/modules/chat_manager.dart';
import 'package:weather/src/modules/youtube.dart';

import 'package:weather/src/platform/telegram_platform.dart';
import 'package:weather/src/platform/discord_platform.dart';

abstract class Platform<T> {
  factory Platform(
      {required ChatManager chatManager,
      required Youtube youtube,
      required String token,
      required String adminId,
      required ChatPlatform chatPlatform}) {
    switch (chatPlatform) {
      case ChatPlatform.telegram:
        return TelegramPlatform(token: token, adminId: adminId, chatManager: chatManager, youtube: youtube);
      case ChatPlatform.discord:
        return DiscordPlatform(token: token, adminId: adminId, chatManager: chatManager, youtube: youtube);
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
  Future sendNoAccessMessage(MessageEvent event);

  @protected
  Future sendErrorMessage(MessageEvent event);

  @protected
  Future<bool> getUserPremiumStatus(String chatId, String userId);

  @protected
  String getMessageId(T message);
}
