import 'dart:async';
import 'package:collection/collection.dart';
import 'package:weather/src/utils.dart';
import 'swearwords_manager.dart';
import 'stonecave.dart';

// 471006081 - Жан
// 354903232 - Денисы
// 225021811 - Вован
// 1439235581 - Димон
// 816477374 - Паша

const String _pathToReputationCave = 'assets/reputation.cave.json';

class ReputationUser {
  final int _defaultOptionsSize = 3;
  final int userId;
  String fullName;
  int reputation;
  int _increaseOptionsLeft = 3;
  int _decreaseOptionsLeft = 3;

  ReputationUser({required this.userId, required this.reputation, this.fullName = ''});

  ReputationUser.fromJson(Map<String, dynamic> json)
      : userId = json['userId'],
        reputation = json['reputation'],
        fullName = json['fullName'];

  bool get canIncrease => _increaseOptionsLeft > 0;

  bool get canDecrease => _decreaseOptionsLeft > 0;

  void resetOptions() {
    _increaseOptionsLeft = _defaultOptionsSize;
    _decreaseOptionsLeft = _defaultOptionsSize;
  }

  void optionUsed(String option) {
    var allowedOptions = ['increase', 'decrease'];
    if (!allowedOptions.contains(option)) {
      return;
    }

    if (option == 'increase' && canIncrease) _increaseOptionsLeft--;
    if (option == 'decrease' && canDecrease) _decreaseOptionsLeft--;
  }

  Map<String, dynamic> toJson() => {'userId': userId, 'reputation': reputation, 'fullName': fullName};
}

class Reputation {
  final int adminId;
  final SwearwordsManager sm;
  final int chatId;
  final List<ReputationUser> _users = [];
  late StoneCave stoneCave;

  Reputation({required this.adminId, required this.sm, required this.chatId});

  Future<void> initReputation() async {
    stoneCave = StoneCave(cavepath: _pathToReputationCave);
    await stoneCave.initialize();

    _updateUsersList();
    _startResetPolling();
  }

  void _updateUsersList() async {
    var lastStone = await stoneCave.getLastStone();
    List stoneUsers = lastStone.data['reputation'];

    _users.clear();

    stoneUsers.forEach((rawUser) {
      var user = ReputationUser.fromJson(rawUser);

      _users.add(user);
    });
  }

  void _startResetPolling() {
    var skip = false;

    Timer.periodic(Duration(seconds: 30), (_) async {
      if (skip) return;

      var hour = DateTime.now().hour;

      if (hour == 0) {
        skip = true;

        _users.forEach((user) => user.resetOptions());

        await sleep(Duration(hours: 23));

        skip = false;
      }
    });
  }

  Future<String> updateReputation(int? from, int? to, String type) async {
    var changeResult = '';

    if (from == null || to == null) {
      return sm.get('error_occurred');
    }

    var isCaveValid = await stoneCave.checkCaveIntegrity();
    if (!isCaveValid) {
      return sm.get('reputation_cave_integrity_failed');
    }

    var changeAuthor = _users.firstWhereOrNull((user) => user.userId == from);
    var userToUpdate = _users.firstWhereOrNull((user) => user.userId == to);

    if (userToUpdate == null || changeAuthor == null) {
      return sm.get('error_occurred');
    }

    if (userToUpdate.userId == changeAuthor.userId) {
      return sm.get('self_admire_attempt');
    }

    if (type == 'increase') {
      if (changeAuthor.canIncrease) {
        userToUpdate.reputation += 1;
        changeAuthor.optionUsed('increase');
        changeResult = sm.get('reputation_increased', {'name': userToUpdate.fullName});
      } else {
        changeResult = sm.get('reputation_change_failed');
      }
    } else if (type == 'decrease') {
      if (changeAuthor.canDecrease) {
        userToUpdate.reputation -= 1;
        changeAuthor.optionUsed('decrease');
        changeResult = sm.get('reputation_decreased', {'name': userToUpdate.fullName});
      } else {
        changeResult = sm.get('reputation_change_failed');
      }
    }

    var updatedReputation = _users.map((user) => user.toJson()).toList();
    await stoneCave.addStone(Stone(data: {'from': changeAuthor.userId, 'to': userToUpdate, 'type': type, 'reputation': updatedReputation}));

    return changeResult;
  }

  String getReputationMessage() {
    var reputationMessage = sm.get('reputation_message_start');

    _users.sort((userA, userB) => userA.reputation - userB.reputation);
    _users.forEach((user) {
      reputationMessage += sm.get('user_reputation', {'name': user.fullName, 'reputation': user.reputation.toString()});
      reputationMessage += '\n';
    });

    return reputationMessage;
  }
}
