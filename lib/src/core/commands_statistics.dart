import 'package:weather/src/globals/chat_platform.dart';
import 'database.dart';

// telegram api get all messages from chat
// https://stackoverflow.com/questions/43477726/how-can-i-get-a-list-of-all-messages-in-telegram-group-via-the-bot-api

class CommandsStatistics {
  final Database db;

  CommandsStatistics({required this.db});

  Future<void> registerCommandInvocation({required String userId, required ChatPlatform platform, required String command}) async {
    var timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.commandsStatistics.createCommandInvocationRecord(userId: userId, platform: platform, command: command, timestamp: timestamp);
  }

  void getStatisticsForChat() {}

  void getStatisticsForUser() {}
}
