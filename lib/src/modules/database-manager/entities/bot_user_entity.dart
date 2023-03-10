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

  Future<List<BotUserData>> getAllUsers() async {
    List rawUsers = await executeQuery(queriesMap['get_all_bot_users']);

    return rawUsers.map((rawUser) => BotUserData(id: rawUser[0], name: rawUser[1], chatId: rawUser[2], isPremium: rawUser[3])).toList();
  }

  Future<int> createUser({required String id, required String chatId, required String name, bool isPremium = false}) {
    return executeTransaction(queriesMap['create_bot_user'], {'id': id, 'chatId': chatId, 'name': name, 'isPremium': isPremium});
  }

  Future<int> deleteUser(String id) {
    return executeTransaction(queriesMap['delete_bot_user'], {'id': id});
  }

  Future<int> updatePremiumStatus(String id, bool isPremium) {
    return executeTransaction(queriesMap['update_premium_status'], {'id': id, 'isPremium': isPremium});
  }
}
