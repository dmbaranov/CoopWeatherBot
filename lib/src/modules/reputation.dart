import 'dart:async';
import 'package:collection/collection.dart';
import 'package:cron/cron.dart';
import 'swearwords_manager.dart';
import 'stonecave.dart';
import 'user_manager.dart';

const String _pathToReputationCave = 'assets/reputation.cave.json';
const int _defaultOptionsSize = 3;
const int _premiumOptionsSize = 6;

class ReputationUser extends UMUser {
  int reputation;
  int _increaseOptionsLeft = _defaultOptionsSize;
  int _decreaseOptionsLeft = _defaultOptionsSize;

  ReputationUser({required id, required name, required this.reputation, isPremium}) : super(id: id, name: name, isPremium: isPremium) {
    resetOptions();
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

  @override
  Map<String, dynamic> toJson() => {'id': id, 'reputation': reputation, 'name': name, 'isPremium': isPremium};
}

class Reputation {
  final SwearwordsManager sm;
  final UserManager userManager;
  final List<ReputationUser> _users = [];
  late StoneCave stoneCave;

  Reputation({required this.sm, required this.userManager});

  Future<void> initialize() async {
    stoneCave = StoneCave(cavepath: _pathToReputationCave);
    await stoneCave.initialize();

    _updateUsersList();
    _startResetVotesJob();
    _subscribeToUsersUpdate();
  }

  void _subscribeToUsersUpdate() {
    var userManagerStream = userManager.userManagerStream;

    userManagerStream.listen((_) => _updateUsersList());
  }

  void _updateUsersList() async {
    var lastStone = await stoneCave.getLastStone();

    if (lastStone == null) return;

    List stoneUsers = lastStone.data['reputation'];

    _users.clear();

    userManager.users.forEach((umUser) {
      var userDataFromStone = stoneUsers.firstWhereOrNull((stoneUser) => stoneUser['id'] == umUser.id);

      var reputationUser =
          ReputationUser(id: umUser.id, name: umUser.name, isPremium: umUser.isPremium, reputation: userDataFromStone?['reputation'] ?? 0);

      _users.add(reputationUser);
    });
  }

  void _startResetVotesJob() {
    Cron().schedule(Schedule.parse('0 0 * * *'), () {
      _users.forEach((user) => user.resetOptions());
    });
  }

  Future<String> updateReputation({required String type, UMUser? from, UMUser? to}) async {
    var changeResult = '';

    if (from == null || to == null) {
      return sm.get('error_occurred');
    }

    var isCaveValid = await stoneCave.checkCaveIntegrity();
    if (!isCaveValid) {
      return sm.get('reputation_cave_integrity_failed');
    }

    var changeAuthor = _users.firstWhereOrNull((user) => user.id == from.id);
    var userToUpdate = _users.firstWhereOrNull((user) => user.id == to.id);

    if (userToUpdate == null || changeAuthor == null) {
      return sm.get('error_occurred');
    }

    if (userToUpdate.id == changeAuthor.id) {
      return sm.get('self_admire_attempt');
    }

    if (type == 'increase') {
      if (changeAuthor.canIncrease) {
        userToUpdate.reputation += 1;
        changeAuthor.optionUsed('increase');
        changeResult = sm.get('reputation_increased', {'name': userToUpdate.name});
      } else {
        changeResult = sm.get('reputation_change_failed');
      }
    } else if (type == 'decrease') {
      if (changeAuthor.canDecrease) {
        userToUpdate.reputation -= 1;
        changeAuthor.optionUsed('decrease');
        changeResult = sm.get('reputation_decreased', {'name': userToUpdate.name});
      } else {
        changeResult = sm.get('reputation_change_failed');
      }
    }

    var updatedReputation = _users.map((user) => user.toJson()).toList();
    await stoneCave.addStone(Stone(data: {'from': changeAuthor.id, 'to': userToUpdate, 'type': type, 'reputation': updatedReputation}));

    return changeResult;
  }

  String getReputationMessage() {
    var reputationMessage = sm.get('reputation_message_start');

    _users.sort((userA, userB) => userB.reputation - userA.reputation);
    _users.forEach((user) {
      reputationMessage += sm.get('user_reputation', {'name': user.name, 'reputation': user.reputation.toString()});
      reputationMessage += '\n';
    });

    return reputationMessage;
  }
}
