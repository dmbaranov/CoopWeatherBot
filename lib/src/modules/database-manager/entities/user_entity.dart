import 'entity.dart';

class UserData {
  final String id;
  final String name;
  final bool isPremium;

  UserData({required this.id, required this.name, required this.isPremium});
}

class UserEntity extends Entity {
  UserEntity({required super.dbConnection}) : super(entityName: 'user');

  Future<List<UserData>> getAllUsers() async {
    List rawUsers = await executeQuery(queriesMap['get_all_users']);

    return rawUsers.map((rawUser) => UserData(id: rawUser[0], name: rawUser[1], isPremium: rawUser[2])).toList();
  }

  Future<void> createUser({required String id, required String name, bool isPremium = false}) async {
    await executeTransaction(queriesMap['create_user'], {'id': id, 'name': name, 'isPremium': isPremium});
  }

  Future<void> deleteUser(String id) async {
    await executeTransaction(queriesMap['delete_user'], {'id': id});
  }

  Future<void> updatePremiumStatus(String id, bool isPremium) async {
    await executeTransaction(queriesMap['update_premium_status'], {'id': id, 'isPremium': isPremium});
  }
}
