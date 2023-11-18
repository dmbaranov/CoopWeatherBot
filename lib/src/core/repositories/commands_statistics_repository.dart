import 'package:weather/src/globals/chat_platform.dart';

import 'repository.dart';

class CommandsStatisticsRepository extends Repository {
  CommandsStatisticsRepository({required super.dbConnection}) : super(repositoryName: 'commands_statistics');

  Future<int> createCommandInvocationRecord(
      {required String userId, required ChatPlatform platform, required String command, required int timestamp}) {
    return executeTransaction(queriesMap['qwe'], {'userId': userId, 'platform': platform, 'command': command, 'timestamp': timestamp});
  }
}
