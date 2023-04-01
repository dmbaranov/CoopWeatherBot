import 'entity.dart';

class BotUserData {
  final String id;
  final String name;
  final String chatId;
  final bool isPremium;

  BotUserData({required this.id, required this.name, required this.chatId, required this.isPremium});
}

class BotUserEntity extends Entity {
  BotUserEntity({required super.dbConnection}) : super(entityName: 'bot_user');

  Future<List<BotUserData>> getAllUsersForChat(String chatId) async {
    var rawUsers = await executeQuery(queriesMap['get_all_bot_users_for_chat'], {'chatId': chatId});

    if (rawUsers == null) {
      return [];
    }

    return rawUsers.map((rawUser) => BotUserData(id: rawUser[0], name: rawUser[1], chatId: rawUser[2], isPremium: rawUser[3])).toList();
  }

  Future<BotUserData?> getSingleChatUser({required String chatId, required String userId}) async {
    var user = await executeQuery(queriesMap['get_single_chat_user'], {'chatId': chatId, 'userId': userId});

    if (user == null) {
      return null;
    }

    var foundUser = user[0];

    return BotUserData(id: foundUser[0], name: foundUser[1], chatId: foundUser[2], isPremium: foundUser[3]);
  }

  Future<int> createUser({required String chatId, required String id, required String name, bool isPremium = false}) {
    return executeTransaction(queriesMap['create_bot_user'], {'userId': id, 'chatId': chatId, 'name': name, 'isPremium': isPremium});
  }

  Future<int> deleteUser(String chatId, String id) {
    return executeTransaction(queriesMap['delete_bot_user'], {'chatId': chatId, 'userId': id});
  }

  Future<int> updatePremiumStatus(String chatId, String id, bool isPremium) {
    return executeTransaction(queriesMap['update_premium_status'], {'chatId': chatId, 'userId': id, 'isPremium': isPremium});
  }
}
