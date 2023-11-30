import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/access_level.dart';
import 'event_bus.dart';
import 'events/access_events.dart';
import 'database.dart';

typedef OnSuccessCallback = void Function(MessageEvent event);
typedef OnFailureCallback = Future Function(MessageEvent event);

class Access {
  final Database db;
  final EventBus eventBus;
  final String adminId;

  Access({required this.db, required this.eventBus, required this.adminId});

  void execute(
      {required MessageEvent event,
      required String command,
      required AccessLevel accessLevel,
      required OnSuccessCallback onSuccess,
      required OnFailureCallback onFailure}) async {
    var user = await db.user.getSingleUserForChat(event.chatId, event.userId);

    if (user == null || user.banned) {
      onFailure(event);

      return;
    }

    if (user.id == adminId) {
      eventBus.fire(AccessEvent(chatId: event.chatId, user: user, command: command));
      onSuccess(event);

      return;
    }

    if (accessLevel == AccessLevel.admin) {
      onFailure(event);

      return;
    }

    if (accessLevel == AccessLevel.moderator && !user.moderator) {
      onFailure(event);

      return;
    }

    eventBus.fire(AccessEvent(chatId: event.chatId, user: user, command: command));
    onSuccess(event);
  }
}
