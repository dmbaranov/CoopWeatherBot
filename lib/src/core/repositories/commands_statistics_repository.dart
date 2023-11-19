import 'package:weather/src/globals/chat_platform.dart';

import 'repository.dart';

class CommandsStatisticsRepository extends Repository {
  CommandsStatisticsRepository({required super.dbConnection}) : super(repositoryName: 'commands_statistics');

  Future<int> createCommandInvocationRecord(
      {required String userId, required String platform, required String command, required String timestamp}) {
    return executeTransaction(queriesMap['create_command_invocation_record'],
        {'userId': userId, 'platform': platform, 'command': command, 'timestamp': timestamp});
  }
}
