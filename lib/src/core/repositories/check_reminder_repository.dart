import 'package:weather/src/core/check_reminder.dart' show CheckReminderData;
import 'repository.dart';

class CheckReminderRepository extends Repository {
  CheckReminderRepository({required super.dbConnection}) : super(repositoryName: 'check_reminder') {}

  Future<int> createCheckReminder(String chatId, String userId, String message, DateTime timestamp) {
    return executeTransaction(
        queriesMap['create_check_reminder'], {'chatId': chatId, 'userId': userId, 'message': message, 'timestamp': timestamp});
  }

  Future<List<CheckReminderData>> getIncompleteCheckReminders() async {
    var rawCheckReminders = await executeQuery(queriesMap['get_incomplete_check_reminders']);

    if (rawCheckReminders == null || rawCheckReminders.isEmpty) {
      return [];
    }

    return rawCheckReminders
        .map((checkReminder) => checkReminder.toColumnMap())
        .map((checkReminder) => CheckReminderData(
            id: checkReminder['id'],
            chatId: checkReminder['chat_id'],
            userId: checkReminder['bot_user_id'],
            message: checkReminder['message'],
            timestamp: checkReminder['timestamp']))
        .toList();
  }

  Future<int> completeCheckReminder(int checkReminderId) {
    return executeTransaction(queriesMap['complete_check_reminder'], {'checkReminderId': checkReminderId});
  }
}
