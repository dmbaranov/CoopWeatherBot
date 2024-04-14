import 'dart:async';
import 'package:cron/cron.dart';
import 'package:weather/src/core/repositories/check_reminder_repository.dart';
import 'package:weather/src/globals/module_exception.dart';
import 'package:weather/src/injector/injection.dart';

// how many reminders from the DB can be active at the same time
const remindersLimit = 50;
// every n minutes fetch reminders from DB that will shoot within this interval
const activeRemindersInterval = 10;

class CheckReminderException extends ModuleException {
  CheckReminderException(super.cause);
}

class CheckReminderData {
  final int id;
  final String chatId;
  final String userId;
  final String message;
  final DateTime timestamp;

  CheckReminderData({required this.id, required this.chatId, required this.userId, required this.message, required this.timestamp});
}

class CheckReminder {
  final CheckReminderRepository _checkReminderDb;
  late StreamController<CheckReminderData> _checkReminderController;
  List<Timer> _checkReminderTimers = [];

  CheckReminder() : _checkReminderDb = getIt<CheckReminderRepository>();

  Stream<CheckReminderData> get checkReminderStream => _checkReminderController.stream;

  void initialize() {
    _checkReminderController = StreamController<CheckReminderData>.broadcast();
    _updateActiveCheckReminderTimers();
    _startUpdateTimersJob();
  }

  Future<bool> createCheckReminder(
      {required String chatId, required String userId, required String period, required String message}) async {
    var [reminderValue, reminderInterval] = _parseReminderPeriod(period);
    _validateCheckReminderParameters(reminderValue, reminderInterval, message);
    var checkReminderTimestamp = _generateReminderTimestamp(reminderValue, reminderInterval);
    var result = await _checkReminderDb.createCheckReminder(chatId, userId, message, checkReminderTimestamp);
    _updateActiveCheckReminderTimers();

    return result == 1;
  }

  List<String> _parseReminderPeriod(String rawPeriod) {
    var periodSplitRegexp = RegExp(r'^(\d+)([a-zA-Z])$');
    var periodMatches = periodSplitRegexp.allMatches(rawPeriod);

    if (periodMatches.isEmpty) {
      throw CheckReminderException('check_reminder.errors.wrong_parameters');
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

    return DateTime(now.year, now.month, checkDays, checkHours, checkMinutes, checkSeconds).toUtc();
  }

  void _validateCheckReminderParameters(String value, String interval, String message) {
    const validPeriodIntervals = ['s', 'm', 'h', 'd'];
    var numericValue = int.tryParse(value);

    if (numericValue == null || message == '') {
      throw CheckReminderException('check_reminder.errors.wrong_parameters');
    }

    if (numericValue > 999) {
      throw CheckReminderException('check_reminder.errors.period_too_big');
    }

    if (numericValue <= 0) {
      throw CheckReminderException('check_reminder.errors.period_too_small');
    }

    if (!validPeriodIntervals.contains(interval)) {
      throw CheckReminderException('check_reminder.errors.possible_period');
    }
  }

  void _updateActiveCheckReminderTimers() async {
    var now = DateTime.now().toUtc();
    var incompleteReminders = await _checkReminderDb.getIncompleteCheckReminders(remindersLimit, activeRemindersInterval);

    _checkReminderTimers.forEach((timer) => timer.cancel());
    _checkReminderTimers = incompleteReminders
        .map((checkReminder) => Timer(checkReminder.timestamp.toUtc().difference(now), () => _completeCheckReminder(checkReminder)))
        .toList();
  }

  void _startUpdateTimersJob() {
    Cron().schedule(Schedule.parse('*/$activeRemindersInterval * * * *'), _updateActiveCheckReminderTimers);
  }

  void _completeCheckReminder(CheckReminderData checkReminder) {
    _checkReminderController.sink.add(checkReminder);
    _checkReminderDb.completeCheckReminder(checkReminder.id);
  }
}
