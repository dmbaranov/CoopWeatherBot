import 'chat_platform.dart';

class MessageEvent<T> {
  // TODO: once accordion poll is not coupled with Telegram platform, remove this field
  final ChatPlatform platform;
  final String chatId;
  final String userId;
  final List<String> parameters;
  final bool isBot;
  final T rawMessage;
  ({String id, String name, bool isPremium})? _otherUser;

  MessageEvent(
      {required this.platform,
      required this.chatId,
      required this.userId,
      required this.isBot,
      required this.parameters,
      required this.rawMessage});

  set otherUser(({String id, String name, bool isPremium})? user) {
    if (_otherUser != null) {
      throw Exception("Attempt to set already defined otherUser");
    }

    _otherUser = user;
  }

  ({String id, String name, bool isPremium})? get otherUser => _otherUser;

  @override
  String toString() {
    return 'MessageEvent({ platform: $platform, chatId: $chatId, userId: $userId, otherUser: $otherUser, parameters: $parameters, isBot: $isBot, rawMessage: $rawMessage })';
  }
}
