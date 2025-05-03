import 'dart:async';
import 'package:cron/cron.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/repositories/command_statistics_repository.dart';
import 'package:weather/src/core/event_bus.dart';
import 'package:weather/src/events/access_events.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/modules/modules_mediator.dart';
import 'package:weather/src/utils/wait_concurrently.dart';

class ChatReport {
  final String chatId;
  final int totalCommandsInvoked;
  final List<(String, int, int)> topInvokedCommands;
  final List<(String, int)> topInvocationUsers;

  ChatReport(
      {required this.chatId, required this.totalCommandsInvoked, required this.topInvokedCommands, required this.topInvocationUsers});
}

class CommandStatistics {
  final ModulesMediator modulesMediator;
  final ChatPlatform chatPlatform;
  final EventBus _eventBus;
  final CommandStatisticsRepository _commandStatisticsDb;

  late StreamController<ChatReport> _chatReportController;

  CommandStatistics({required this.modulesMediator, required this.chatPlatform})
      : _commandStatisticsDb = getIt<CommandStatisticsRepository>(),
        _eventBus = getIt<EventBus>();

  Stream<ChatReport> get chatReportStream => _chatReportController.stream;

  void initialize() {
    _chatReportController = StreamController<ChatReport>.broadcast();

    _listenToAccessEvents();
    _startMonthlyTopJob();
  }

  Future<void> _registerCommandInvocation({required String chatId, required String userId, required String command}) async {
    var timestamp = DateTime.now().toString();

    await _commandStatisticsDb.createCommandInvocationRecord(chatId: chatId, userId: userId, command: command, timestamp: timestamp);
  }

  Future<List<(String, int)>> getChatCommandInvocations({required String chatId}) {
    return _commandStatisticsDb.getChatCommandInvocations(chatId: chatId);
  }

  Future<List<(String, String, int)>> getUserCommandInvocations({required String userId}) {
    return _commandStatisticsDb.getUserInvocationsStatistics(userId: userId);
  }

  void _listenToAccessEvents() {
    _eventBus
        .on<AccessEvent>()
        .listen((event) => _registerCommandInvocation(chatId: event.chatId, userId: event.user.id, command: event.command));
  }

  void _startMonthlyTopJob() async {
    Cron().schedule(Schedule.parse('0 10 1 * *'), () async {
      var platformChatIds = await modulesMediator.chat.getAllChatIdsForPlatform(chatPlatform);

      Future.forEach(platformChatIds, (chatId) async {
        var (totalCommandsInvoked, topInvokedCommands, topInvocationUsers) =
            await waitConcurrently3<int, List<(String, int, int)>, List<(String, int)>>(
                _commandStatisticsDb.getMonthlyCommandInvokesNumber(chatId: chatId),
                _commandStatisticsDb.getTopMonthlyCommandInvocations(chatId: chatId),
                _commandStatisticsDb.getTopMonthlyCommandInvocationUsers(chatId: chatId));

        _chatReportController.sink.add(ChatReport(
            chatId: chatId,
            totalCommandsInvoked: totalCommandsInvoked,
            topInvokedCommands: topInvokedCommands,
            topInvocationUsers: topInvocationUsers));
      });
    });
  }
}
