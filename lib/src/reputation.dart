import 'dart:async';
import 'dart:io' as io;
import 'dart:convert';
import 'package:teledart/model.dart';
import 'package:teledart/telegram.dart';

// 128723556 - me
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
  final int chatId;
  final List<ReputationUser> _users = [];

  Reputation({this.adminId, this.telegram, this.chatId});

  void initReputation() async {
    _updateUsersList();
    _startResetPolling();
  }

  void _updateUsersList() async {
    var rawReputationData = await io.File(_pathToReputationData).readAsString();
    List<dynamic> reputationData = await json.decode(rawReputationData);

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
      await message.reply('Нахуй пошол, мудило!!1');
      return;
    }

    var changeAuthor =
        _users.firstWhere((user) => user.userId == message.from.id, orElse: () => null);
    var userToUpdate = _users.firstWhere((user) => user.userId == message.reply_to_message.from.id,
        orElse: () => null);

    if (userToUpdate == null || changeAuthor == null) {
      await message.reply('Нахуй пошол, мудило!!1');
      return;
    }

    if (userToUpdate.userId == changeAuthor.userId) {
      await message.reply('Ахахах, он самолайкает, ёпта!');
      return;
    }

    if (type == 'increase') {
      if (changeAuthor.canIncrease) {
        userToUpdate.reputation += 1;
        changeAuthor.optionUsed('increase');
        await message
            .reply('Вечер в хату, ${userToUpdate.fullName}, твоя репутация была увеличена!');
        await _logReputationChange(changeAuthor.userId, userToUpdate.userId, 'increase');
      }
    } else if (type == 'decrease') {
      if (changeAuthor.canDecrease) {
        userToUpdate.reputation -= 1;
        changeAuthor.optionUsed('decrease');
        await message.reply(
            'Пики точеные или хуи дроченые, ${userToUpdate.fullName}?! Твоя репутация была понижена');
        await _logReputationChange(changeAuthor.userId, userToUpdate.userId, 'decrease');
      }
    }
    _saveReputationData();
  }

  void sendReputationList([TeleDartMessage message]) async {
    var reputationMessage = 'Такие дела посоны:\n\n';

    _users.sort((userA, userB) => userB.reputation - userA.reputation);
    _users.forEach((user) {
      reputationMessage += 'У ${user.fullName} репутация ${user.reputation}\n';
    });

    await telegram.sendMessage(chatId, reputationMessage);
  }

  void generateReputationUsers(TeleDartMessage message) async {
    for (var user in _users) {
      var telegramUser = await telegram.getChatMember(chatId, user.userId);
      var userName = '';
      if (telegramUser.user.first_name != null) userName += telegramUser.user.first_name;
      if (telegramUser.user.username != null) userName += ' <${telegramUser.user.first_name}> ';
      if (telegramUser.user.last_name != null) userName += telegramUser.user.last_name;

      user.fullName = userName;
      await sleep(Duration(milliseconds: 200));
    }

    _saveReputationData();
    _updateUsersList();
  }

  void _logReputationChange(int authorId, int receiverId, String type) async {
    var cacheFile = io.File(_pathToReputationLogFile);

    await cacheFile.writeAsStringSync('${authorId} ${type} to ${receiverId} on ${DateTime.now()}\n',
        mode: io.FileMode.append);
  }

  bool setReputation(TeleDartMessage message) {
    // TODO: add admin right to change reputation in whatever way you want
    if (!_accessAllowed(message)) return false;

    return true;
  }
}
