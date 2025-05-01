class MessageEvent<T> {
  final String chatId;
  final String userId;
  final List<String> parameters;
  final T rawMessage;
  ({String id, String name, bool isPremium, bool isBot})? _otherUser;

  MessageEvent({required this.chatId, required this.userId, required this.parameters, required this.rawMessage});

  set otherUser(({String id, String name, bool isPremium, bool isBot})? user) {
    if (_otherUser != null) {
      throw Exception('Attempt to set already defined otherUser');
    }

    _otherUser = user;
  }

  ({String id, String name, bool isPremium, bool isBot})? get otherUser => _otherUser;

  @override
  String toString() {
    return 'MessageEvent({ chatId: $chatId, userId: $userId, otherUser: $otherUser, parameters: $parameters, rawMessage: $rawMessage })';
  }
}
