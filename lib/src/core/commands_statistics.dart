import 'package:weather/src/core/events/access_events.dart';
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

  Future<void> _registerCommandInvocation({required String chatId, required String userId, required String command}) async {
    var timestamp = DateTime.now().toString();

    await db.commandsStatistics.createCommandInvocationRecord(chatId: chatId, userId: userId, command: command, timestamp: timestamp);
  }

  void getStatisticsForChat() {}

  void getStatisticsForUser() {}

  void _listenToAccessEvents() {
    eventBus
        .on<AccessEvent>()
        .listen((event) => _registerCommandInvocation(chatId: event.chatId, userId: event.user.id, command: event.command));
  }
}
