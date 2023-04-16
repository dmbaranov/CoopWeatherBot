import 'chat_manager.dart' show ChatPlatform;

class MessageEvent {
  final ChatPlatform platform;
  final String chatId;
  final String userId;
  final String message;
  final List<String> otherUserIds;
  final List<String> parameters;
  final bool isBot;
  final dynamic rawMessage;

  MessageEvent(
      {required this.platform,
      required this.chatId,
      required this.userId,
      required this.isBot,
      required this.message,
      required this.otherUserIds,
      required this.parameters,
      required this.rawMessage});
}

class CommandsManager {
  void userCommand(MessageEvent event, {required Function onFailure, Function? onSuccess, Function? onSuccessCustom}) {
    // check permission
    if (false) {
      onFailure(event);

      return;
    }

    if (onSuccessCustom != null) {
      onSuccessCustom();
    } else if (onSuccess != null) {
      onSuccess(event);
    } else {
      onFailure(event);
    }
  }

  void moderatorCommand(MessageEvent event, {required Function onFailure, Function? onSuccess, Function? onSuccessCustom}) {
    // check permission
    if (false) {
      onFailure(event);

      return;
    }

    if (onSuccessCustom != null) {
      onSuccessCustom();
    } else if (onSuccess != null) {
      onSuccess(event);
    } else {
      onFailure(event);
    }
  }

  void adminCommand(MessageEvent event, {required Function onFailure, Function? onSuccess, Function? onSuccessCustom}) {
    // check permission
    if (false) {
      onFailure(event);

      return;
    }

    if (onSuccessCustom != null) {
      onSuccessCustom();
    } else if (onSuccess != null) {
      onSuccess(event);
    } else {
      onFailure(event);
    }
  }
}
