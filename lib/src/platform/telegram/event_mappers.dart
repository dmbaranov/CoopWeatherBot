import 'package:teledart/model.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/chat_platform.dart';

// TODO: make a single transformer instead? Take everything that is available
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
