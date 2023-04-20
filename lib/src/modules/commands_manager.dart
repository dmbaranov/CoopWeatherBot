import 'chat_manager.dart' show ChatPlatform;

typedef CommandsWrapper = void Function(MessageEvent event, {required Function onFailure, Function? onSuccess, Function? onSuccessCustom});
typedef OnSuccessCallback = void Function(MessageEvent event);

class MessageEvent<T> {
  final ChatPlatform platform;
  final String chatId;
  final String userId;
  final String message;
  final List<String> otherUserIds;
  final List<String> parameters;
  final bool isBot;
  final T rawMessage;

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

class Command<T> {
  final String command;
  final String description;
  final CommandsWrapper wrapper;
  final bool withParameters;
  final bool withOtherUserIds;
  final OnSuccessCallback successCallback;

  Command(
      {required this.command,
      required this.description,
      required this.wrapper,
      required this.successCallback,
      this.withParameters = false,
      this.withOtherUserIds = false});
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
