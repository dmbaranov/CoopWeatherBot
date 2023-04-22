import 'package:weather/src/modules/database-manager/database_manager.dart';

import 'chat_manager.dart' show ChatPlatform;

typedef CommandsWrapper = void Function(MessageEvent event, {required Function onFailure, Function? onSuccess, Function? onSuccessCustom});
typedef OnSuccessCallback = void Function(MessageEvent event);

// TODO: remove rawMessage?
class MessageEvent<T> {
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
}

class Command<T> {
  final String command;
  final String description;
  final CommandsWrapper wrapper;
  final bool withParameters;
  final bool withOtherUserIds;
  final bool conversatorCommand;
  final OnSuccessCallback successCallback;

  Command(
      {required this.command,
      required this.description,
      required this.wrapper,
      required this.successCallback,
      this.withParameters = false,
      this.withOtherUserIds = false,
      this.conversatorCommand = false});
}

// TODO: instead of querying database every time, use a cache
class CommandsManager {
  final String adminId;
  final DatabaseManager dbManager;

  CommandsManager({required this.adminId, required this.dbManager});

  void userCommand(MessageEvent event, {required Function onFailure, Function? onSuccess, Function? onSuccessCustom}) async {
    var user = await dbManager.user.getSingleUserForChat(event.chatId, event.userId);

    if (event.userId != adminId) {
      if (user == null) {
        onFailure(event);

        return;
      }
    }

    if (onSuccessCustom != null) {
      onSuccessCustom();
    } else if (onSuccess != null) {
      onSuccess(event);
    } else {
      onFailure(event);
    }
  }

  void moderatorCommand(MessageEvent event, {required Function onFailure, Function? onSuccess, Function? onSuccessCustom}) async {
    var user = await dbManager.user.getSingleUserForChat(event.chatId, event.userId);

    if (event.userId != adminId) {
      if (user == null || (!user.moderator && user.id != adminId)) {
        onFailure(event);

        return;
      }
    }

    if (onSuccessCustom != null) {
      onSuccessCustom();
    } else if (onSuccess != null) {
      onSuccess(event);
    } else {
      onFailure(event);
    }
  }

  void adminCommand(MessageEvent event, {required Function onFailure, Function? onSuccess, Function? onSuccessCustom}) async {
    if (event.userId != adminId) {
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
