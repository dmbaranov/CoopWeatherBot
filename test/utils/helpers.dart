import 'package:postgres/postgres.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';

List<ResultRow> sortResults(Result results) {
  return results.toList()..sort((a, b) => a[0].toString().compareTo(b[0].toString()));
}

MessageEvent getFakeMessageEvent(
    {ChatPlatform? platform,
    String? chatId,
    String? userId,
    ({String id, String name, bool isPremium})? otherUser,
    List<String>? parameters,
    bool? isBot,
    String? rawMessage}) {
  return MessageEvent(
      platform: platform ?? ChatPlatform.telegram,
      chatId: chatId ?? '123',
      userId: userId ?? '123',
      isBot: isBot ?? false,
      parameters: parameters ?? [],
      rawMessage: rawMessage)
    ..otherUser = otherUser;
}
