import 'package:weather/src/core/check_reminder.dart' show CheckReminderData;
import 'repository.dart';

class CheckReminderRepository extends Repository {
  CheckReminderRepository({required super.dbConnection}) : super(repositoryName: 'check_reminder') {}

  Future<int> createCheckReminder(String chatId, String userId, String message, DateTime timestamp) {
    return executeTransaction(
        queriesMap['create_check_reminder'], {'chatId': chatId, 'userId': userId, 'message': message, 'timestamp': timestamp});
  }
}
