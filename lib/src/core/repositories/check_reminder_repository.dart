import 'package:injectable/injectable.dart';
import 'package:weather/src/core/check_reminder.dart' show CheckReminderData;
import 'repository.dart';

@singleton
class CheckReminderRepository extends Repository {
  CheckReminderRepository({required super.db}) : super(repositoryName: 'check_reminder');

  Future<int> createCheckReminder(String chatId, String userId, String message, DateTime timestamp) {
    return db.executeTransaction(
        queriesMap['create_check_reminder'], {'chatId': chatId, 'userId': userId, 'message': message, 'timestamp': timestamp});
  }

  Future<List<CheckReminderData>> getIncompleteCheckReminders(int remindersLimit, int timestampInterval) async {
    var rawCheckReminders = await db.executeQuery(
        queriesMap['get_incomplete_check_reminders'], {'remindersLimit': remindersLimit, 'timestampInterval': timestampInterval});

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
    return db.executeTransaction(queriesMap['complete_check_reminder'], {'checkReminderId': checkReminderId});
  }
}
