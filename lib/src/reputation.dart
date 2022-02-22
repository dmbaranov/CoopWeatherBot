import 'dart:async';
import 'dart:io' as io;
import 'dart:convert';
import 'package:teledart/model.dart';
import 'package:teledart/telegram.dart';
import 'swearwords_manager.dart';

// 471006081 - Жан
// 354903232 - Денисы
// 225021811 - Вован
// 1439235581 - Димон
// 816477374 - Паша

const String _pathToReputationData = 'assets/reputation.json';
const String _pathToReputationLogFile = 'assets/reputationlog.txt';

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

  Reputation({this.adminId, this.telegram, this.sm, this.chatId});

  void initReputation() {
    _updateUsersList();
    _startResetPolling();
  }

  void _updateUsersList() async {
    var rawReputationData = await io.File(_pathToReputationData).readAsString();
    List<dynamic> reputationData = json.decode(rawReputationData);

    _users.clear();
    reputationData.forEach((data) {
      var user = ReputationUser(
          userId: data['userId'], reputation: data['reputation'], fullName: data['fullName']);
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

  void _saveReputationData() async {
    var reputationFile = io.File(_pathToReputationData);
    var result = _users.map((user) => user.toJson()).toList();

    await reputationFile.writeAsString(json.encode(result));
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
        _logReputationChange(changeAuthor.userId, userToUpdate.userId, 'increase');
      } else {
        await message.reply(sm.get('reputation_change_failed'));
      }
    } else if (type == 'decrease') {
      if (changeAuthor.canDecrease) {
        userToUpdate.reputation -= 1;
        changeAuthor.optionUsed('decrease');
        await message.reply(sm.get('reputation_decreased', {'name': userToUpdate.fullName}));
        _logReputationChange(changeAuthor.userId, userToUpdate.userId, 'decrease');
      } else {
        await message.reply(sm.get('reputation_change_failed'));
      }
    }
    _saveReputationData();
  }

  void sendReputationList([TeleDartMessage message]) async {
    var reputationMessage = sm.get('reputation_message_start');

    _users.sort((userA, userB) => userB.reputation - userA.reputation);
    _users.forEach((user) {
      reputationMessage += sm.get(
          'user_reputation', {'name': user.fullName, 'reputation': user.reputation.toString()});
    });

    await telegram.sendMessage(chatId, reputationMessage);
  }

  void generateReputationUsers(TeleDartMessage message) async {
    if (!_accessAllowed(message)) return;

    for (var user in _users) {
      var telegramUser = await telegram.getChatMember(chatId, user.userId);
      var userName = '';
      if (telegramUser.user.first_name != null) userName += telegramUser.user.first_name;
      if (telegramUser.user.username != null) userName += ' <${telegramUser.user.username}> ';
      if (telegramUser.user.last_name != null) userName += telegramUser.user.last_name;

      user.fullName = userName;
      await sleep(Duration(milliseconds: 200));
    }

    _saveReputationData();
    _updateUsersList();
  }

  void _logReputationChange(int authorId, int receiverId, String type) {
    var cacheFile = io.File(_pathToReputationLogFile);

    cacheFile.writeAsStringSync('$authorId $type to $receiverId on ${DateTime.now()}\n',
        mode: io.FileMode.append);
  }

  bool setReputation(TeleDartMessage message) {
    // TODO: add admin right to change reputation in whatever way you want
    if (!_accessAllowed(message)) return false;

    return true;
  }
}
