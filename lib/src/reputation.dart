import 'dart:async';
import 'package:teledart/model.dart';
import 'package:teledart/telegram.dart';
import 'swearwords_manager.dart';
import 'stonecave.dart';

// 471006081 - Жан
// 354903232 - Денисы
// 225021811 - Вован
// 1439235581 - Димон
// 816477374 - Паша

const String _pathToReputationCave = 'assets/reputation.cave.json';

Future sleep(Duration duration) {
  return Future.delayed(duration, () => null);
}

class ReputationUser {
  final int _defaultOptionsSize = 3;
  final int userId;
  String fullName;
  int reputation;
  int _increaseOptionsLeft = 3;
  int _decreaseOptionsLeft = 3;

  ReputationUser({this.userId, this.reputation, this.fullName = ''});

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

  Map<String, dynamic> toJson() =>
      {'userId': userId, 'reputation': reputation, 'fullName': fullName};
}

class Reputation {
  final int adminId;
  final Telegram telegram;
  final SwearwordsManager sm;
  final int chatId;
  final List<ReputationUser> _users = [];
  StoneCave stoneCave;

  Reputation({this.adminId, this.telegram, this.stoneCave, this.sm, this.chatId});

  void initReputation() async {
    stoneCave = StoneCave(cavepath: _pathToReputationCave);
    await stoneCave.initialize();

    _updateUsersList();
    _startResetPolling();
  }

  void _updateUsersList() async {
    List lastStoneUsers = stoneCave.getLastStone().data['reputation'];

    _users.clear();

    lastStoneUsers.forEach((rawUser) {
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

  bool _accessAllowed(TeleDartMessage message) {
    return message.from.id == adminId;
  }

  void updateReputation(TeleDartMessage message, String type) async {
    if (message.reply_to_message == null) {
      await message.reply(sm.get('error_occurred'));
      return;
    }

    var changeAuthor =
        _users.firstWhere((user) => user.userId == message.from.id, orElse: () => null);
    var userToUpdate = _users.firstWhere((user) => user.userId == message.reply_to_message.from.id,
        orElse: () => null);

    if (userToUpdate == null || changeAuthor == null) {
      await message.reply(sm.get('error_occurred'));
      return;
    }

    if (userToUpdate.userId == changeAuthor.userId) {
      await message.reply(sm.get('self_admire_attempt'));
      return;
    }

    if (type == 'increase') {
      if (changeAuthor.canIncrease) {
        userToUpdate.reputation += 1;
        changeAuthor.optionUsed('increase');
        await message.reply(sm.get('reputation_increased', {'name': userToUpdate.fullName}));
      } else {
        await message.reply(sm.get('reputation_change_failed'));
      }
    } else if (type == 'decrease') {
      if (changeAuthor.canDecrease) {
        userToUpdate.reputation -= 1;
        changeAuthor.optionUsed('decrease');
        await message.reply(sm.get('reputation_decreased', {'name': userToUpdate.fullName}));
      } else {
        await message.reply(sm.get('reputation_change_failed'));
      }
    }

    var updatedReputation = _users.map((user) => user.toJson()).toList();
    await stoneCave.addStone(Stone(data: {
      'from': changeAuthor.userId,
      'to': userToUpdate,
      'type': type,
      'reputation': updatedReputation
    }));
  }

  void sendReputationList([TeleDartMessage message]) async {
    var reputationMessage = sm.get('reputation_message_start');

    _users.sort((userA, userB) => userB.reputation - userA.reputation);
    _users.forEach((user) {
      reputationMessage += sm.get(
          'user_reputation', {'name': user.fullName, 'reputation': user.reputation.toString()});
      reputationMessage += '\n';
    });

    await telegram.sendMessage(chatId, reputationMessage);
  }

  bool setReputation(TeleDartMessage message) {
    // TODO: add admin right to change reputation in whatever way you want
    if (!_accessAllowed(message)) return false;

    return true;
  }
}
