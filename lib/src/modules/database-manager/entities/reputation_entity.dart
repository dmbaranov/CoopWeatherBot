import 'entity.dart';

class SingleReputationData {
  final String id;
  final int reputation;
  final int increaseOptionsLeft;
  final int decreaseOptionsLeft;

  SingleReputationData({required this.id, required this.reputation, required this.increaseOptionsLeft, required this.decreaseOptionsLeft});
}

class ChatReputationData {
  final String name;
  final int reputation;

  ChatReputationData({required this.name, required this.reputation});
}

class ReputationEntity extends Entity {
  ReputationEntity({required super.dbConnection}) : super(entityName: 'reputation');

  Future<List<ChatReputationData>> getReputationForChat(String chatId) async {
    var rawReputation = await executeQuery(queriesMap['get_reputation_for_chat'], {'chatId': chatId});

    if (rawReputation == null || rawReputation.isEmpty) {
      return [];
    }

    return rawReputation.map((reputation) => ChatReputationData(name: reputation[0], reputation: reputation[1])).toList();
  }

  Future<SingleReputationData?> getSingleReputationData(String chatId, String userId) async {
    var data = await executeQuery(queriesMap['get_single_reputation_data'], {'chatId': chatId, 'userId': userId});

    if (data == null || data.isEmpty) {
      return null;
    }

    if (data.length != 1) {
      print('One piece of reputation data data was expected, got ${data.length} instead');

      return null;
    }

    var reputationData = data[0];

    return SingleReputationData(
        id: reputationData[0],
        reputation: reputationData[1],
        increaseOptionsLeft: reputationData[2],
        decreaseOptionsLeft: reputationData[3]);
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
