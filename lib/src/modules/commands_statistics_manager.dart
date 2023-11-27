import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/commands_statistics.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/event_bus.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'utils.dart';

class CommandsStatisticsManager {
  final Platform platform;
  final Database db;
  final EventBus eventBus;
  final Chat chat;
  final CommandsStatistics _commandsStatistics;

  CommandsStatisticsManager({required this.platform, required this.db, required this.eventBus, required this.chat})
      : _commandsStatistics = CommandsStatistics(db: db, eventBus: eventBus);

  void initialize() {
    _commandsStatistics.initialize();
  }

  void getChatCommandInvocations(MessageEvent event) async {
    var chatId = event.chatId;
    var commandsInvocationData = await _commandsStatistics.getChatCommandInvocations(chatId: chatId);
    var invocationsMessage = _buildChatCommandInvocationsMessage(commandsInvocationData);
    var successfulMessage = chat.getText(chatId, 'commands_statistics.chat_invocations_statistics', {'invocations': invocationsMessage});

    sendOperationMessage(chatId,
        platform: platform, operationResult: commandsInvocationData.isNotEmpty, successfulMessage: successfulMessage);
  }
}

String _buildChatCommandInvocationsMessage(List<(String, int)> invocationsData) {
  var invocationsMessage = '';

  invocationsData.forEach((invocationData) {
    var (command, count) = invocationData;
    invocationsMessage += '$command: $count\n';
  });

  return invocationsMessage;
}
