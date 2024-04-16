import 'package:injectable/injectable.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/utils/logger.dart';
import 'package:weather/src/events/access_events.dart';
import 'repositories/bot_user_repository.dart';
import 'event_bus.dart';

typedef OnSuccessCallback = void Function(MessageEvent event);
typedef OnFailureCallback = Future Function(MessageEvent event);

@Order(2)
@singleton
class Access {
  final Config _config;
  final BotUserRepository _userDb;
  final EventBus _eventBus;
  final Logger _logger;

  Access()
      : _config = getIt<Config>(),
        _userDb = getIt<BotUserRepository>(),
        _eventBus = getIt<EventBus>(),
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
    var canExecuteAsAdmin = user.id == _config.adminId;

    if (canExecuteAsUser || canExecuteAsModerator || canExecuteAsAdmin) {
      _logger.i('Executing /$command with event: $event');
      _eventBus.fire(AccessEvent(chatId: event.chatId, user: user, command: command));

      return onSuccess(event);
    }

    return onFailure(event);
  }
}
