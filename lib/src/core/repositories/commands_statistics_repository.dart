import 'repository.dart';

class CommandsStatisticsRepository extends Repository {
  CommandsStatisticsRepository({required super.dbConnection}) : super(repositoryName: 'commands_statistics');

  Future<int> createCommandInvocationRecord(
      {required String chatId, required String userId, required String command, required String timestamp}) {
    return executeTransaction(
        queriesMap['create_command_invocation_record'], {'chatId': chatId, 'userId': userId, 'command': command, 'timestamp': timestamp});
  }
}
