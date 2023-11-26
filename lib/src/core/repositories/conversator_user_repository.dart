import 'package:weather/src/core/conversator.dart' show ConversatorUser;
import 'repository.dart';

class ConversatorUserRepository extends Repository {
  ConversatorUserRepository({required super.dbConnection}) : super(repositoryName: 'conversator_user');

  Future<ConversatorUser> getConversatorUser(String userId) async {
    var user = await executeQuery(queriesMap['get_conversator_user'], {'userId': userId});

    if (user == null || user.isEmpty) {
      return createConversatorUser(userId).then((_) => getConversatorUser(userId));
    }

    var userData = user[0].toColumnMap();

    return ConversatorUser(
        id: userData['id'],
        dailyRegularInvocations: userData['daily_regular_invocations'],
        totalRegularInvocations: userData['total_regular_invocations'],
        dailyAdvancedInvocations: userData['daily_advanced_invocations'],
        totalAdvancedInvocations: userData['total_advanced_invocations']);
  }

  Future<int> createConversatorUser(String userId) {
    return executeTransaction(queriesMap['create_conversator_user'], {'userId': userId});
  }

  Future<int> updateRegularInvocations(String userId) {
    return executeTransaction(queriesMap['increment_regular_invocations'], {'userId': userId});
  }

  Future<int> updateAdvancedInvocations(String userId) {
    return executeTransaction(queriesMap['increment_advanced_invocations'], {'userId': userId});
  }

  Future<int> resetDailyInvocations() {
    return executeTransaction(queriesMap['reset_daily_invocations']);
  }
}
