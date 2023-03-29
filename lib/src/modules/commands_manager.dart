class MessageEvent {
  final String chatId;
  final String? userId;
  final String? message;
  final List<String> otherUserIds;
  final List<String> parameters;
  final bool? isBot;

  MessageEvent(
      {required this.chatId,
      required this.userId,
      required this.isBot,
      required this.message,
      required this.otherUserIds,
      required this.parameters});
}

class CommandsManager {
  void userCommand(MessageEvent event, {required Function onSuccess, required Function onFailure}) {
    // check permission
    if (true) {
      onSuccess(event);
    } else {
      onFailure(event);
    }
  }

  void moderatorCommand(MessageEvent event, {required Function onSuccess, required Function onFailure}) {
    if (true) {
      onSuccess(event);
    } else {
      onFailure(event);
    }
  }

  void adminCommand(MessageEvent event, {required Function onSuccess, required Function onFailure}) {
    if (true) {
      onSuccess(event);
    } else {
      onFailure(event);
    }
  }
}
