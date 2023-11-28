import 'package:weather/src/core/events/access_events.dart';
import 'database.dart';
import 'event_bus.dart';

class CommandStatistics {
  final Database db;
  final EventBus eventBus;

  CommandStatistics({required this.db, required this.eventBus});

  void initialize() {
    _listenToAccessEvents();
  }

  Future<void> _registerCommandInvocation({required String chatId, required String userId, required String command}) async {
    var timestamp = DateTime.now().toString();

    await db.commandStatistics.createCommandInvocationRecord(chatId: chatId, userId: userId, command: command, timestamp: timestamp);
  }

  Future<List<(String, int)>> getChatCommandInvocations({required String chatId}) {
    return db.commandStatistics.getChatCommandInvocations(chatId: chatId);
  }

  Future<List<(String, String, int)>> getUserCommandInvocations({required String userId}) {
    return db.commandStatistics.getUserInvocationsStatistics(userId: userId);
  }

  void getStatisticsForUser() {}

  void _listenToAccessEvents() {
    eventBus
        .on<AccessEvent>()
        .listen((event) => _registerCommandInvocation(chatId: event.chatId, userId: event.user.id, command: event.command));
  }
}
