import 'repository.dart';

class CommandStatisticsRepository extends Repository {
  CommandStatisticsRepository({required super.dbConnection}) : super(repositoryName: 'commands_statistics');

  Future<int> createCommandInvocationRecord(
      {required String chatId, required String userId, required String command, required String timestamp}) {
    return executeTransaction(
        queriesMap['create_command_invocation_record'], {'chatId': chatId, 'userId': userId, 'command': command, 'timestamp': timestamp});
  }

  Future<List<(String, int)>> getChatCommandInvocations({required String chatId}) async {
    var invocations = await executeQuery(queriesMap['get_chat_command_invocations'], {'chatId': chatId});

    if (invocations == null || invocations.isEmpty) {
      return [];
    }

    return invocations
        .map<Map<String, dynamic>>((invocation) => invocation.toColumnMap())
        .map<(String, int)>((invocationData) => (invocationData['command'], invocationData['count']))
        .toList();
  }

  Future<List<(String, String, int)>> getUserInvocationsStatistics({required String userId}) async {
    var invocations = await executeQuery(queriesMap['get_user_command_invocations'], {'userId': userId});

    if (invocations == null || invocations.isEmpty) {
      return [];
    }

    return invocations
        .map<Map<String, dynamic>>((invocation) => invocation.toColumnMap())
        .map<(String, String, int)>((invocationData) => (invocationData['name'], invocationData['command'], invocationData['count']))
        .toList();
  }
}
