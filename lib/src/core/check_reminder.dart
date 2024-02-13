import 'dart:async';
import 'database.dart';

class CheckReminderData {
  final int id;
  final String chatId;
  final String userId;
  final String message;
  final DateTime timestamp;

  CheckReminderData({required this.id, required this.chatId, required this.userId, required this.message, required this.timestamp});
}

class CheckReminder {
  final Database db;

  late StreamController<CheckReminderData> _checkReminderController;

  CheckReminder({required this.db});

  Stream<CheckReminderData> get checkReminderStream => _checkReminderController.stream;

  void initialize() {
    _checkReminderController = StreamController<CheckReminderData>.broadcast();
    _startExistingCheckTimers();
  }

  Future<bool> createCheckReminder(
      {required String chatId, required String userId, required String period, required String message}) async {
    var [reminderValue, reminderInterval] = _parseReminderPeriod(period);
    _validateCheckReminderParameters(reminderValue, reminderInterval, message);
    var checkReminderTimestamp = _generateReminderTimestamp(reminderValue, reminderInterval);
    var result = await db.checkReminderRepository.createCheckReminder(chatId, userId, message, checkReminderTimestamp);

    // TODO: create Timer
    return result == 1;
  }

  List<String> _parseReminderPeriod(String rawPeriod) {
    var periodSplitRegexp = RegExp(r'^(\d+)([a-zA-Z])$');
    var periodMatches = periodSplitRegexp.allMatches(rawPeriod);

    if (periodMatches.isEmpty) {
      throw Exception('Incorrect parameters');
    }

    var [reminderValue, reminderInterval] = periodMatches.map((m) => [m.group(1) ?? '', m.group(2) ?? '']).expand((pair) => pair).toList();

    return [reminderValue, reminderInterval];
  }

  DateTime _generateReminderTimestamp(String reminderValue, String interval) {
    var numericValue = int.parse(reminderValue);

    var now = DateTime.now();
    var checkDays = interval == 'd' ? now.day + numericValue : now.day;
    var checkHours = interval == 'h' ? now.hour + numericValue : now.hour;
    var checkMinutes = interval == 'm' ? now.minute + numericValue : now.minute;
    var checkSeconds = interval == 's' ? now.second + numericValue : now.second;

    return DateTime(now.year, now.month, checkDays, checkHours, checkMinutes, checkSeconds);
  }

  void _validateCheckReminderParameters(String value, String interval, String message) {
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

  void _startExistingCheckTimers() async {
    var now = DateTime.now();
    var incompleteReminders = await db.checkReminderRepository.getIncompleteCheckReminders();

    await Future.forEach(incompleteReminders, (checkReminder) async {
      if (checkReminder.timestamp.isAfter(now)) {
        await db.checkReminderRepository.completeCheckReminder(checkReminder.id);
        _checkReminderController.sink.add(checkReminder);
      }
    });
  }
}
