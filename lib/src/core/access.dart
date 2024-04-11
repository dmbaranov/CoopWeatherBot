import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/utils/logger.dart';
import 'events/access_events.dart';
import 'repositories/bot_user_repository_inj.dart';
import 'event_bus.dart';

typedef OnSuccessCallback = void Function(MessageEvent event);
typedef OnFailureCallback = Future Function(MessageEvent event);

class Access {
  final EventBus eventBus;
  final String adminId;
  final BotUserRepositoryInj _userDb;
  final Logger _logger;

  Access({required this.eventBus, required this.adminId})
      : _userDb = getIt<BotUserRepositoryInj>(),
        _logger = getIt<Logger>();

  void execute(
      {required MessageEvent event,
      required String command,
      required AccessLevel accessLevel,
      required OnSuccessCallback onSuccess,
      required OnFailureCallback onFailure}) async {
    var user = await _userDb.getSingleUserForChat(event.chatId, event.userId);

    if (user == null || user.banned || user.deleted) {
      return onFailure(event);
    }

    var canExecuteAsUser = accessLevel == AccessLevel.user;
    var canExecuteAsModerator = accessLevel == AccessLevel.moderator && user.moderator;
    var canExecuteAsAdmin = user.id == adminId;

    if (canExecuteAsUser || canExecuteAsModerator || canExecuteAsAdmin) {
      _logger.i('Executing /$command with event: $event');
      eventBus.fire(AccessEvent(chatId: event.chatId, user: user, command: command));

      return onSuccess(event);
    }

    return onFailure(event);
  }
}
