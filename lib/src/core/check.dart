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
    var [reminderValue, reminderInterval] = _parseReminderPeriod(period);
    var checkReminderDate = _generateReminderDate(reminderValue, reminderInterval);

    print(checkReminderDate);
  }

  void _startExistingCheckTimers() {
    print('get data from the db and create timers');
  }

  List<String> _parseReminderPeriod(String rawPeriod) {
    var periodSplitRegexp = RegExp(r'(-\d+)(\D+)');
    var periodMatches = periodSplitRegexp.allMatches(rawPeriod);

    if (periodMatches.isEmpty) {
      throw Exception('Incorrect parameters');
    }

    var [reminderValue, reminderInterval] = periodMatches.map((m) => [m.group(1) ?? '', m.group(2) ?? '']).expand((pair) => pair).toList();

    _validatePeriod(reminderValue, reminderInterval);

    return [reminderValue, reminderInterval];
  }

  DateTime _generateReminderDate(String reminderValue, String interval) {
    var numericValue = int.parse(reminderValue);

    var now = DateTime.now();
    var checkDays = interval == 'd' ? now.day + numericValue : now.day;
    var checkHours = interval == 'h' ? now.hour + numericValue : now.hour;
    var checkMinutes = interval == 'm' ? now.minute + numericValue : now.minute;
    var checkSeconds = interval == 's' ? now.second + numericValue : now.second;

    return DateTime(now.year, now.month, checkDays, checkHours, checkMinutes, checkSeconds);
  }

  void _validatePeriod(String value, String interval) {
    const validPeriodIntervals = ['s', 'm', 'h', 'd'];
    var numericValue = int.tryParse(value);

    if (numericValue == null) {
      throw Exception('Incorrect format');
    }

    if (numericValue > 999) {
      throw Exception('Too big');
    }

    if (numericValue <= 0) {
      throw Exception('Too small');
    }

    if (!validPeriodIntervals.contains(interval)) {
      throw Exception('Supported intervals are s, m, h and d');
    }
  }
}
