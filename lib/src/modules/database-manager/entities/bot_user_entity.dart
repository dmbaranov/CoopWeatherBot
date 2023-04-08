import 'package:postgres/postgres.dart';

import 'entity.dart';

class BotUserData {
  final String id;
  final String name;
  final bool isPremium;
  final bool deleted;
  final bool banned;
  final bool moderator;

  BotUserData(
      {required this.id,
      required this.name,
      required this.isPremium,
      required this.deleted,
      required this.banned,
      required this.moderator});
}

class BotUserEntity extends Entity {
  BotUserEntity({required super.dbConnection}) : super(entityName: 'bot_user');

  Future<List<BotUserData>> getAllUsersForChat(String chatId) async {
    var rawUsers = await executeQuery(queriesMap['get_all_bot_users_for_chat'], {'chatId': chatId});

    if (rawUsers == null) {
      return [];
    }

    return rawUsers.map(_mapUser).toList();
  }

  Future<BotUserData?> getSingleChatUser({required String chatId, required String userId}) async {
    var user = await executeQuery(queriesMap['get_single_chat_user'], {'chatId': chatId, 'userId': userId});

    if (user == null) {
      return null;
    }

    return _mapUser(user[0]);
  }

  Future<int> createUser({required String chatId, required String userId, required String name, bool isPremium = false}) async {
    // TODO: add support to execute multiple queries in a single transaction
    var createUserResult =
        await executeTransaction(queriesMap['create_bot_user'], {'userId': userId, 'chatId': chatId, 'name': name, 'isPremium': isPremium});

    var createChatMemberResult = await executeTransaction(queriesMap['create_chat_member'], {'userId': userId, 'chatId': chatId});

    return createUserResult + createChatMemberResult;
  }

  Future<int> deleteUser(String chatId, String userId) {
    return executeTransaction(queriesMap['delete_bot_user'], {'chatId': chatId, 'userId': userId});
  }

  Future<int> updatePremiumStatus(String chatId, String userId, bool isPremium) {
    return executeTransaction(queriesMap['update_premium_status'], {'chatId': chatId, 'userId': userId, 'isPremium': isPremium});
  }

  BotUserData _mapUser(PostgreSQLResultRow foundUser) {
    return BotUserData(
        id: foundUser[0],
        name: foundUser[1],
        isPremium: foundUser[2],
        deleted: foundUser[3],
        banned: foundUser[4],
        moderator: foundUser[5]);
  }
}
