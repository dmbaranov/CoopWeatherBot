import 'package:weather/src/core/reputation.dart' show SingleReputationData, ChatReputationData;
import 'repository.dart';

class ReputationRepository extends Repository {
  ReputationRepository({required super.dbConnection}) : super(repositoryName: 'reputation');

  Future<List<ChatReputationData>> getReputationForChat(String chatId) async {
    var rawReputation = await executeQuery(queriesMap['get_reputation_for_chat'], {'chatId': chatId});

    if (rawReputation == null || rawReputation.isEmpty) {
      return [];
    }

    return rawReputation
        .map((reputation) => reputation.toColumnMap())
        .map((reputation) => ChatReputationData(name: reputation['name'], reputation: reputation['reputation']))
        .toList();
  }

  Future<SingleReputationData?> getSingleReputationData(String chatId, String userId) async {
    var data = await executeQuery(queriesMap['get_single_reputation_data'], {'chatId': chatId, 'userId': userId});

    if (data == null || data.isEmpty) {
      return null;
    }

    var reputationData = data[0].toColumnMap();

    return SingleReputationData(
        id: reputationData['bot_user_id'],
        reputation: reputationData['reputation'],
        increaseOptionsLeft: reputationData['increase_options_left'],
        decreaseOptionsLeft: reputationData['decrease_options_left']);
  }

  Future<int> updateReputation(String chatId, String userId, int reputation) {
    return executeTransaction(queriesMap['update_reputation'], {'chatId': chatId, 'userId': userId, 'reputation': reputation});
  }

  Future<int> updateChangeOptions(String chatId, String userId, int increaseOptionsLeft, int decreaseOptionsLeft) {
    return executeTransaction(queriesMap['update_change_options'],
        {'chatId': chatId, 'userId': userId, 'increaseOptionsLeft': increaseOptionsLeft, 'decreaseOptionsLeft': decreaseOptionsLeft});
  }

  Future<int> createReputationData(String chatId, String userId, int numberOfOptions) {
    return executeTransaction(queriesMap['create_reputation_data'],
        {'chatId': chatId, 'userId': userId, 'increaseOptionsLeft': numberOfOptions, 'decreaseOptionsLeft': numberOfOptions});
  }

  Future<int> resetChangeOptions(int numberOfOptions) {
    return executeTransaction(
        queriesMap['reset_change_options'], {'increaseOptionsLeft': numberOfOptions, 'decreaseOptionsLeft': numberOfOptions});
  }
}
