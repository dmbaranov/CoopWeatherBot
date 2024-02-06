import 'dart:async';

import 'package:weather/src/core/user.dart';

import 'database.dart';

class CheckReminder {
  final String chatId;
  final BotUser user;
  final String message;

  CheckReminder({required this.chatId, required this.user, required this.message});
}

class Check {
  final Database db;

  late StreamController<CheckReminder> _checkReminderController;

  Check({required this.db});

  Stream<CheckReminder> get checkReminderStream => _checkReminderController.stream;

  void initialize() {
    _startExistingCheckTimers();
  }

  Future<void> createCheckReminder(
      {required String chatId, required String userId, required String period, required String message}) async {
    print('Creating new check...');
  }

  void _startExistingCheckTimers() {
    print('get data from the db and create timers');
  }
}
