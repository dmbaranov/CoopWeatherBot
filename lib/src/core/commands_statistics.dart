import 'package:weather/src/core/events/access_events.dart';
import 'database.dart';
import 'event_bus.dart';

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

  Future<List<(String, int)>> getChatCommandInvocations({required String chatId}) {
    return db.commandsStatistics.getChatCommandInvocations(chatId: chatId);
  }

  void getStatisticsForUser() {}

  void _listenToAccessEvents() {
    eventBus
        .on<AccessEvent>()
        .listen((event) => _registerCommandInvocation(chatId: event.chatId, userId: event.user.id, command: event.command));
  }
}
