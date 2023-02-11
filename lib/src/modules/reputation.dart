import 'dart:async';
import 'package:collection/collection.dart';
import 'package:cron/cron.dart';
import 'swearwords_manager.dart';
import 'stonecave.dart';

const String _pathToReputationCave = 'assets/reputation.cave.json';
const int _defaultOptionsSize = 3;
const int _premiumOptionsSize = 6;

class ReputationUser {
  final String userId;
  String fullName;
  int reputation;
  bool isPremium;
  int _increaseOptionsLeft = _defaultOptionsSize;
  int _decreaseOptionsLeft = _defaultOptionsSize;

  ReputationUser.fromJson(Map<String, dynamic> json)
      : userId = json['userId'],
        fullName = json['fullName'] ?? '',
        reputation = json['reputation'] ?? 0,
        isPremium = json['isPremium'] ?? false {
    resetOptions();

    if (isPremium && !fullName.contains('⭐')) {
      fullName += ' ⭐';
    } else if (!isPremium && fullName.contains('⭐')) {
      fullName = fullName.replaceAll(' ⭐', '');
    }
  }

  bool get canIncrease => _increaseOptionsLeft > 0;

  bool get canDecrease => _decreaseOptionsLeft > 0;

  void resetOptions() {
    _increaseOptionsLeft = isPremium ? _premiumOptionsSize : _defaultOptionsSize;
    _decreaseOptionsLeft = isPremium ? _premiumOptionsSize : _defaultOptionsSize;
  }

  void optionUsed(String option) {
    var allowedOptions = ['increase', 'decrease'];
    if (!allowedOptions.contains(option)) {
      return;
    }

    if (option == 'increase' && canIncrease) _increaseOptionsLeft--;
    if (option == 'decrease' && canDecrease) _decreaseOptionsLeft--;
  }

  Map<String, dynamic> toJson() => {'userId': userId, 'reputation': reputation, 'fullName': fullName, 'isPremium': isPremium};
}

class Reputation {
  final SwearwordsManager sm;
  final List<ReputationUser> _users = [];
  late StoneCave stoneCave;

  Reputation({required this.sm});

  Future<void> initReputation() async {
    stoneCave = StoneCave(cavepath: _pathToReputationCave);
    await stoneCave.initialize();

    _updateUsersList();
    _startResetVotesJob();
  }

  void _updateUsersList() async {
    var lastStone = await stoneCave.getLastStone();

    if (lastStone == null) return;

    List stoneUsers = lastStone.data['reputation'];

    _users.clear();

    stoneUsers.forEach((rawUser) {
      var user = ReputationUser.fromJson(rawUser);

      _users.add(user);
    });
  }

  void _startResetVotesJob() {
    Cron().schedule(Schedule.parse('0 0 * * *'), () {
      _users.forEach((user) => user.resetOptions());
    });
  }

  Future<String> updateReputation({required String type, String? from, String? to, bool? isPremium}) async {
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

    if (isPremium != null) {
      changeAuthor.isPremium = isPremium;
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

    _users.sort((userA, userB) => userB.reputation - userA.reputation);
    _users.forEach((user) {
      reputationMessage += sm.get('user_reputation', {'name': user.fullName, 'reputation': user.reputation.toString()});
      reputationMessage += '\n';
    });

    return reputationMessage;
  }

  Future setUsers(List<ReputationUser> users) async {
    var lastStone = await stoneCave.getLastStone();
    Map<String, ReputationUser> existingUsers = {};

    if (lastStone != null) {
      List stoneUsers = lastStone.data['reputation'];
      stoneUsers.forEach((user) {
        existingUsers[user['userId']] = ReputationUser.fromJson(user);
      });
    }

    _users.clear();

    users.forEach((user) {
      var existingUser = existingUsers[user.userId];

      if (existingUser != null) {
        user.reputation = existingUser.reputation;
      }

      _users.add(user);
    });
  }
}
