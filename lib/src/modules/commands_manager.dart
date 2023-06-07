import 'package:weather/src/modules/database-manager/database_manager.dart';

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
