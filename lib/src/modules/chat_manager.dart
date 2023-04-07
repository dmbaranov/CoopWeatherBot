import 'database-manager/database_manager.dart';

enum ChatPlatform {
  telegram('telegram'),
  discord('discord');

  final String value;

  const ChatPlatform(this.value);
}

class ChatManager {
  final DatabaseManager dbManager;

  ChatManager({required this.dbManager});

  Future<bool> createChat({required String id, required String name, required ChatPlatform platform}) async {
    var creationResult = await dbManager.chat.createChat(id, name, platform.toString());

    return creationResult == 1;
  }

  Future<List<String>> getAllChatIds(ChatPlatform platform) {
    return dbManager.chat.getAllChatIds(platform.value);
  }
}
