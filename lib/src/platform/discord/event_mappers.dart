import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:weather/src/platform/shared/message_event.dart';
import 'package:weather/src/platform/shared/chat_platform.dart';

MessageEvent mapDiscordEventToGeneralMessageEvent(IChatContext event) {
  return MessageEvent(
      platform: ChatPlatform.discord,
      chatId: event.guild?.id.toString() ?? '',
      userId: event.user.id.toString(),
      otherUserIds: [],
      isBot: event.user.bot,
      parameters: [],
      rawMessage: event);
}

// MessageEvent mapToEventWithParameters(TeleDartMessage event, List otherParameters) {}
