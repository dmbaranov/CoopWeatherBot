import 'dart:async';
import 'package:cron/cron.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'events/access_events.dart';
import 'database.dart';
import 'event_bus.dart';
import 'chat.dart';

class ChatReport {
  final String chatId;
  final int totalCommandsInvoked;
  final List<(String, int, int)> topInvokedCommands;
  final List<(String, int)> topInvocationUsers;

  ChatReport(
      {required this.chatId, required this.totalCommandsInvoked, required this.topInvokedCommands, required this.topInvocationUsers});
}

class CommandStatistics {
  final Database db;
  final EventBus eventBus;
  final Chat chat;
  final ChatPlatform chatPlatform;

  late StreamController<ChatReport> _chatReportController;

  CommandStatistics({required this.db, required this.eventBus, required this.chat, required this.chatPlatform});

  Stream<ChatReport> get chatReportStream => _chatReportController.stream;

  void initialize() {
    _chatReportController = StreamController<ChatReport>.broadcast();

    _listenToAccessEvents();
    _startMonthlyTopJob();
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

  void _listenToAccessEvents() {
    eventBus
        .on<AccessEvent>()
        .listen((event) => _registerCommandInvocation(chatId: event.chatId, userId: event.user.id, command: event.command));
  }

  void _startMonthlyTopJob() async {
    Cron().schedule(Schedule.parse('0 10 1 * *'), () async {
      var platformChatIds = await chat.getAllChatIdsForPlatform(chatPlatform);

      Future.forEach(platformChatIds, (chatId) async {
        var totalCommandsInvoked = await db.commandStatistics.getMonthlyCommandInvokesNumber(chatId: chatId);
        var topInvokedCommands = await db.commandStatistics.getTopMonthlyCommandInvocations(chatId: chatId);
        var topInvocationUsers = await db.commandStatistics.getTopMonthlyCommandInvocationUsers(chatId: chatId);

        _chatReportController.sink.add(ChatReport(
            chatId: chatId,
            totalCommandsInvoked: totalCommandsInvoked,
            topInvokedCommands: topInvokedCommands,
            topInvocationUsers: topInvocationUsers));
      });
    });
  }
}
