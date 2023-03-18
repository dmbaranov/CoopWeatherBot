import 'database-manager/database_manager.dart';

class ChatManager {
  final DatabaseManager dbManager;

  ChatManager({required this.dbManager});

  Future<bool> createChat({required String id, required String name}) async {
    var creationResult = await dbManager.chat.createChat(id: id, name: name);

    return creationResult == 1;
  }

  Future<List<String>> getAllChatIds() {
    return dbManager.chat.getAllChatIds();
  }
}
