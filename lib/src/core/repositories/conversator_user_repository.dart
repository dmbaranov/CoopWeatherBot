import '../conversator.dart' show ConversatorUser;
import 'repository.dart';

class ConversatorUserRepository extends Repository {
  ConversatorUserRepository({required super.dbConnection}) : super(repositoryName: 'conversator_user');

  Future<ConversatorUser> getConversatorUser(String userId) async {
    var user = await executeQuery(queriesMap['get_conversator_user'], {'userId': userId});

    if (user == null || user.isEmpty) {
      return createConversatorUser(userId).then((_) => getConversatorUser(userId));
    }

    var userData = user[0];

    return ConversatorUser(
        id: userData[0],
        dailyRegularInvocations: userData[1],
        totalRegularInvocations: userData[2],
        dailyAdvancedInvocations: userData[3],
        totalAdvancedInvocations: userData[4]);
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
