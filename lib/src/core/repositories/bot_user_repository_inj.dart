import 'package:injectable/injectable.dart';
import 'package:weather/src/core/user.dart' show BotUser;
import 'repository_inj_two.dart';

@singleton
class BotUserRepositoryInj extends RepositoryInjTwo {
  BotUserRepositoryInj({required super.db}) : super(repositoryName: 'bot_user');

  Future<List<BotUser>> getAllUsersForChat(String chatId) async {
    var rawUsers = await db.executeQuery(queriesMap['get_all_bot_users_for_chat'], {'chatId': chatId});

    if (rawUsers == null || rawUsers.isEmpty) {
      return [];
    }

    return rawUsers.map((user) => _mapUser(user.toColumnMap())).toList();
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
