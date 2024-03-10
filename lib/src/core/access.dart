import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/utils/logger.dart';
import 'events/access_events.dart';
import 'database.dart';
import 'event_bus.dart';

typedef OnSuccessCallback = void Function(MessageEvent event);
typedef OnFailureCallback = Future Function(MessageEvent event);

class Access {
  final Database db;
  final EventBus eventBus;
  final String adminId;
  final Logger _logger;

  Access({required this.db, required this.eventBus, required this.adminId}) : _logger = getIt<Logger>();

  void execute(
      {required MessageEvent event,
      required String command,
      required AccessLevel accessLevel,
      required OnSuccessCallback onSuccess,
      required OnFailureCallback onFailure}) async {
    var user = await db.user.getSingleUserForChat(event.chatId, event.userId);

    if (user == null || user.banned) {
      return onFailure(event);
    }

    var canExecuteAsAdmin = user.id == adminId;
    var canExecuteAsModerator = accessLevel == AccessLevel.moderator && user.moderator;

    if (canExecuteAsAdmin || canExecuteAsModerator) {
      _logger.i('Executing /$command with event: $event');
      eventBus.fire(AccessEvent(chatId: event.chatId, user: user, command: command));

      return onSuccess(event);
    }

    return onFailure(event);
  }
}
