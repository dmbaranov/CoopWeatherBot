import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/modules/modules_mediator.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/utils/logger.dart';
import 'command_statistics.dart';
import '../utils.dart';

class CommandStatisticsManager {
  final Platform platform;
  final ModulesMediator modulesMediator;
  final Logger _logger;
  final Swearwords _sw;
  final CommandStatistics _commandStatistics;

  CommandStatisticsManager({required this.platform, required this.modulesMediator})
      : _logger = getIt<Logger>(),
        _sw = getIt<Swearwords>(),
        _commandStatistics = CommandStatistics(chatPlatform: platform.chatPlatform, chat: modulesMediator.chat);

  void initialize() {
    _commandStatistics.initialize();
    _subscribeToChatReports();
    modulesMediator.registerModule(_commandStatistics);
  }

  void getChatCommandInvocations(MessageEvent event) async {
    var chatId = event.chatId;
    var commandInvocationData = await _commandStatistics.getChatCommandInvocations(chatId: chatId);
    var invocationsMessage = _buildCommandInvocationsMessage(commandInvocationData);
    var successfulMessage = _sw.getText(chatId, 'command_statistics.chat_invocations_statistics', {'invocations': invocationsMessage});

    sendOperationMessage(chatId,
        platform: platform, operationResult: commandInvocationData.isNotEmpty, successfulMessage: successfulMessage);
  }

  void getUserCommandInvocations(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;

    var userId = event.otherUserIds[0];
    var chatId = event.chatId;
    var userCommandInvocationData = await _commandStatistics.getUserCommandInvocations(userId: userId);
    var userName = userCommandInvocationData.elementAtOrNull(0)?.$1 ?? '';
    var noNameInvocationData = userCommandInvocationData.map((data) => (data.$2, data.$3)).toList();
    var invocationsMessage = _buildCommandInvocationsMessage(noNameInvocationData);
    var successfulMessage =
        _sw.getText(chatId, 'command_statistics.user_invocations_data', {'user': userName, 'invocations': invocationsMessage});

    sendOperationMessage(chatId,
        platform: platform, operationResult: userCommandInvocationData.isNotEmpty, successfulMessage: successfulMessage);
  }

  void _subscribeToChatReports() {
    _commandStatistics.chatReportStream.listen((chatReport) async {
      _logger.i('Handling chat report data: $chatReport');

      var chatId = chatReport.chatId;

      var successfulMessage = '';
      var totalCommandsInvoked = chatReport.totalCommandsInvoked;
      var topUsers = chatReport.topInvocationUsers.map((userData) => '${userData.$1}: ${userData.$2}').join('\n');
      var topCommands =
          chatReport.topInvokedCommands.map((commandData) => '${commandData.$1}: ${commandData.$2} (${commandData.$3}%)').join('\n');

      successfulMessage +=
          _sw.getText(chatId, 'command_statistics.chat_report.total_commands_invoked', {'number': totalCommandsInvoked.toString()});
      successfulMessage += _sw.getText(chatId, 'command_statistics.chat_report.top_users', {'topUsers': topUsers});
      successfulMessage += _sw.getText(chatId, 'command_statistics.chat_report.top_commands', {'topCommands': topCommands});

      sendOperationMessage(chatId, platform: platform, operationResult: true, successfulMessage: successfulMessage);
    });
  }

  String _buildCommandInvocationsMessage(List<(String, int)> invocationsData) {
    var invocationsMessage = '';

    invocationsData.forEach((invocationData) {
      var (command, count) = invocationData;
      invocationsMessage += '$command: $count\n';
    });

    return invocationsMessage;
  }
}
