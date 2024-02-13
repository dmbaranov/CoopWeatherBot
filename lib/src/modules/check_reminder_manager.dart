import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/check_reminder.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'utils.dart';

class CheckReminderManager {
  final Platform platform;
  final Database db;
  final Chat chat;
  final CheckReminder _checkReminder;

  CheckReminderManager({required this.platform, required this.db, required this.chat}) : _checkReminder = CheckReminder(db: db);

  void initialize() {
    _checkReminder.initialize();
    _subscribeToCheckUpdates();
  }

  void checkMessage(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.userId;
    var period = event.parameters[0];
    var message = event.parameters.sublist(1).join(' ');
    var check = await _checkReminder.createCheckReminder(chatId: chatId, userId: userId, period: period, message: message);
  }

  void _subscribeToCheckUpdates() {
    _checkReminder.checkReminderStream.listen((checkReminder) {
      sendOperationMessage(checkReminder.chatId, platform: platform, operationResult: true, successfulMessage: checkReminder.message);
    });
  }
}
