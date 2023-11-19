import 'package:weather/src/core/events/access_events.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'database.dart';
import 'event_bus.dart';

// telegram api get all messages from chat
// https://stackoverflow.com/questions/43477726/how-can-i-get-a-list-of-all-messages-in-telegram-group-via-the-bot-api

class CommandsStatistics {
  final Database db;
  final EventBus eventBus;

  CommandsStatistics({required this.db, required this.eventBus});

  void initialize() {
    _listenToAccessEvents();
  }

  Future<void> _registerCommandInvocation({required String userId, required ChatPlatform platform, required String command}) async {
    var timestamp = DateTime.now().toString();

    await db.commandsStatistics
        .createCommandInvocationRecord(userId: userId, platform: platform.value, command: command, timestamp: timestamp);
  }

  void getStatisticsForChat() {}

  void getStatisticsForUser() {}

  void _listenToAccessEvents() {
    eventBus
        .on<AccessEvent>()
        .listen((event) => _registerCommandInvocation(userId: event.user.id, platform: event.platform, command: event.command));
  }
}
