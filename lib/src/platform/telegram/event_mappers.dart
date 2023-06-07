import 'package:teledart/model.dart';
import 'package:weather/src/platform/shared/message_event.dart';
import 'package:weather/src/platform/shared/chat_platform.dart';

MessageEvent mapTelegramEventToGeneralMessageEvent(TeleDartMessage event) {
  return MessageEvent(
      platform: ChatPlatform.telegram,
      chatId: event.chat.id.toString(),
      userId: event.from?.id.toString() ?? '',
      isBot: event.replyToMessage?.from?.isBot ?? false,
      otherUserIds: [],
      parameters: [],
      rawMessage: event);
}

// MessageEvent mapToEventWithParameters(TeleDartMessage event, List otherParameters) {}
