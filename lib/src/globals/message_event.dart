import 'chat_platform.dart';

class MessageEvent<T> {
  // TODO: once accordion poll is not coupled with Telegram platform, remove this field
  final ChatPlatform platform;
  final String chatId;
  final String userId;
  final List<String> otherUserIds;
  final List<String> parameters;
  final bool isBot;
  final T rawMessage;

  MessageEvent(
      {required this.platform,
      required this.chatId,
      required this.userId,
      required this.isBot,
      required this.otherUserIds,
      required this.parameters,
      required this.rawMessage});

  @override
  String toString() {
    return 'MessageEvent({ platform: $platform, chatId: $chatId, userId: $userId, otherUserIds: $otherUserIds, parameters: $parameters, isBot: $isBot, rawMessage: $rawMessage })';
  }
}
