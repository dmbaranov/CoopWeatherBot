import 'dart:async';
import 'package:cron/cron.dart';
import 'database-manager/database_manager.dart';
import 'database-manager/entities/reputation_entity.dart' show ReputationData;

// class ReputationUser extends UMUser {
//   int reputation;
//   int _increaseOptionsLeft = _defaultOptionsSize;
//   int _decreaseOptionsLeft = _defaultOptionsSize;
//
//   ReputationUser({required id, required name, required this.reputation, isPremium}) : super(id: id, name: name, isPremium: isPremium) {
//     resetOptions();
//   }
//
//   bool get canIncrease => _increaseOptionsLeft > 0;
//
//   bool get canDecrease => _decreaseOptionsLeft > 0;
//
//   void resetOptions() {
//     _increaseOptionsLeft = isPremium ? _premiumOptionsSize : _defaultOptionsSize;
//     _decreaseOptionsLeft = isPremium ? _premiumOptionsSize : _defaultOptionsSize;
//   }
//
//   void optionUsed(String option) {
//     var allowedOptions = ['increase', 'decrease'];
//     if (!allowedOptions.contains(option)) {
//       return;
//     }
//
//     if (option == 'increase' && canIncrease) _increaseOptionsLeft--;
//     if (option == 'decrease' && canDecrease) _decreaseOptionsLeft--;
//   }
//
//   Map<String, dynamic> toJson() => {'id': id, 'reputation': reputation, 'name': name, 'isPremium': isPremium};
// }

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
      // return false;
    }

    if (!_canIncreaseReputationCheck(fromUser)) {
      return false;
    }

    var newReputationValue = change == ChangeOption.increase ? toUser.reputation + 1 : toUser.reputation - 1;

    return _updateReputation(chatId, toUserId, newReputationValue);
  }

  Future<bool> createReputationData(String chatId, String userId) async {
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

  // bool _increaseReputation(ReputationData fromUser, ReputationData toUser) {
  //   print('increasing');
  //
  //   return true;
  // }
  //
  // bool _decreaseReputation(ReputationData fromUser, ReputationData toUser) {
  //   print('decreasing');
  //
  //   return false;
  // }

  bool _canIncreaseReputationCheck(ReputationData user) {
    return user.increaseOptionsLeft > 0;
  }

  bool _canDecreaseReputationCheck(ReputationData user) {
    return user.decreaseOptionsLeft > 0;
  }
}
