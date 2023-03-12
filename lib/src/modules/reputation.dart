import 'dart:async';
import 'package:cron/cron.dart';
import 'database-manager/database_manager.dart';
import 'database-manager/entities/reputation_entity.dart' show ReputationData;

enum ChangeOption { increase, decrease }

class Reputation {
  final DatabaseManager dbManager;

  Reputation({required this.dbManager});

  void initialize() {
    _startResetVotesJob();
  }

  void _startResetVotesJob() {
    Cron().schedule(Schedule.parse('0 0 * * *'), () {
      // TODO: update user votes
    });
  }

  Future<bool> updateReputation(
      {required String chatId, required String fromUserId, required String toUserId, required ChangeOption change}) async {
    var fromUser = await dbManager.reputation.getSingleReputationData(chatId, fromUserId);
    var toUser = await dbManager.reputation.getSingleReputationData(chatId, toUserId);

    if (fromUser == null || toUser == null) {
      return false;
    }

    if (fromUserId == toUserId) {
      return false;
    }

    if (change == ChangeOption.increase && !_canIncreaseReputationCheck(fromUser)) {
      return false;
    } else if (change == ChangeOption.decrease && !_canDecreaseReputationCheck(fromUser)) {
      return false;
    }

    var reputationValue = toUser.reputation;
    var increaseOptions = fromUser.increaseOptionsLeft;
    var decreaseOptions = fromUser.decreaseOptionsLeft;

    if (change == ChangeOption.increase) {
      reputationValue += 1;
      increaseOptions -= 1;
    } else {
      reputationValue -= 1;
      decreaseOptions -= 1;
    }

    var optionsUpdated = await _updateChangeOptions(chatId, fromUserId, increaseOptions, decreaseOptions);

    if (!optionsUpdated) {
      return false;
    }

    return _updateReputation(chatId, toUserId, reputationValue);
  }

  Future<bool> createReputationData(String chatId, String userId) async {
    // TODO: add 6 options for premium users
    var result = await dbManager.reputation.createReputationData(chatId, userId, 3);

    return result == 1;
  }

  String getReputationMessage() {
    return '';
    // var reputationMessage = sm.get('reputation_message_start');

    // _users.sort((userA, userB) => userB.reputation - userA.reputation);
    // _users.forEach((user) {
    //   reputationMessage += sm.get('user_reputation', {'name': user.name, 'reputation': user.reputation.toString()});
    //   reputationMessage += '\n';
    // });

    // return reputationMessage;
  }

  Future<bool> _updateReputation(String chatId, String userId, int reputation) async {
    var result = await dbManager.reputation.updateReputation(chatId, userId, reputation);

    return result == 1;
  }

  Future<bool> _updateChangeOptions(String chatId, String userId, int increaseOptions, int decreaseOptions) async {
    var result = await dbManager.reputation.updateChangeOptions(chatId, userId, increaseOptions, decreaseOptions);

    return result == 1;
  }

  bool _canIncreaseReputationCheck(ReputationData user) {
    return user.increaseOptionsLeft > 0;
  }

  bool _canDecreaseReputationCheck(ReputationData user) {
    return user.decreaseOptionsLeft > 0;
  }
}
