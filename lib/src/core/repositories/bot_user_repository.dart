import 'package:weather/src/core/user.dart' show BotUser;
import 'repository.dart';

class BotUserRepository extends Repository {
  BotUserRepository({required super.dbConnection}) : super(repositoryName: 'bot_user');

  Future<List<BotUser>> getAllUsersForChat(String chatId) async {
    var rawUsers = await executeQuery(queriesMap['get_all_bot_users_for_chat'], {'chatId': chatId});

    if (rawUsers == null || rawUsers.isEmpty) {
      return [];
    }

    return rawUsers.map((user) => _mapUser(user.toColumnMap())).toList();
  }

  Future<BotUser?> getSingleUserForChat(String chatId, String userId) async {
    var rawUser = await executeQuery(queriesMap['get_single_user_for_chat'], {'chatId': chatId, 'userId': userId});

    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    return _mapUser(rawUser[0].toColumnMap());
  }

  Future<int> createUser({required String chatId, required String userId, required String name, bool isPremium = false}) async {
    // TODO: add support to execute multiple queries in a single transaction
    var createUserResult =
        await executeTransaction(queriesMap['create_bot_user'], {'userId': userId, 'name': name, 'isPremium': isPremium});

    var createChatMemberResult = await executeTransaction(queriesMap['create_chat_member'], {'userId': userId, 'chatId': chatId});

    return createUserResult + createChatMemberResult;
  }

  Future<int> deleteUser(String chatId, String userId) {
    return executeTransaction(queriesMap['delete_bot_user'], {'chatId': chatId, 'userId': userId});
  }

  Future<int> updatePremiumStatus(String userId, bool isPremium) {
    return executeTransaction(queriesMap['update_premium_status'], {'userId': userId, 'isPremium': isPremium});
  }

  BotUser _mapUser(Map<String, dynamic> foundUser) {
    return BotUser(
        id: foundUser['id'],
        name: foundUser['name'],
        isPremium: foundUser['is_premium'],
        deleted: foundUser['deleted'],
        banned: foundUser['banned'],
        moderator: foundUser['moderator']);
  }
}
