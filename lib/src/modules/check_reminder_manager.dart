import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/check_reminder.dart';
import 'package:weather/src/core/user.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'utils.dart';

class CheckReminderManager {
  final Platform platform;
  final Database db;
  final Chat chat;
  final User user;
  final CheckReminder _checkReminder;

  CheckReminderManager({required this.platform, required this.db, required this.chat, required this.user})
      : _checkReminder = CheckReminder(db: db);

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

    try {
      var result = await _checkReminder.createCheckReminder(chatId: chatId, userId: userId, period: period, message: message);
      var successfulMessage = chat.getText(chatId, 'check_reminder.created');

      sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
    } catch (err) {
      var errorMessage = err.toString().substring(11);

      if (errorMessage.startsWith('check_reminder')) {
        platform.sendMessage(chatId, translation: errorMessage);
      } else {
        platform.sendMessage(chatId, translation: 'general.something_went_wrong');
      }
    }
  }

  void _subscribeToCheckUpdates() {
    _checkReminder.checkReminderStream.listen((checkReminder) async {
      var userData = await user.getSingleUserForChat(checkReminder.chatId, checkReminder.userId);

      if (userData != null) {
        var checkReminderMessage =
            chat.getText(checkReminder.chatId, 'check_reminder.reminder', {'user': userData.name, 'message': checkReminder.message});

        sendOperationMessage(checkReminder.chatId, platform: platform, operationResult: true, successfulMessage: checkReminderMessage);
      } else {
        print("Could not send reminder, user not found. chatId: ${checkReminder.chatId}, userId: ${checkReminder.userId}");
      }
    });
  }
}
