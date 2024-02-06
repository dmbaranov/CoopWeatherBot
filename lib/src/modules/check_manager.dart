import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/check.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'utils.dart';

class CheckManager {
  final Platform platform;
  final Database db;
  final Chat chat;
  final Check _check;

  CheckManager({required this.platform, required this.db, required this.chat}) : _check = Check(db: db);

  void initialize() {
    _check.initialize();
    _subscribeToCheckUpdates();
  }

  void checkMessage(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.userId;
    var period = event.parameters[0];
    var message = event.parameters.sublist(1).join(' ');
    var check = await _check.createCheckReminder(chatId: chatId, userId: userId, period: period, message: message);
  }

  void _subscribeToCheckUpdates() {
    _check.checkReminderStream.listen((checkReminder) {
      print('Sending check to the chat...');
    });
  }
}
