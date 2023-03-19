import 'entity.dart';

class ChatEntity extends Entity {
  ChatEntity({required super.dbConnection}) : super(entityName: 'chat');

  Future<int> createChat(String id, String name) {
    return executeTransaction(queriesMap['create_chat'], {'chatId': id, 'name': name});
  }

  Future<List<String>> getAllChatIds() async {
    var ids = await executeQuery(queriesMap['get_all_chat_ids']);

    if (ids == null) {
      return [];
    }

    return ids.map((rawId) => rawId[0].toString()).toList();
  }
}
