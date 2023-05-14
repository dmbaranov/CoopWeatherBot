import 'package:weather/src/modules/chat_manager.dart';
import 'entity.dart';

class ChatData {
  final String id;
  final String name;
  final ChatPlatform platform;
  final String swearwordsConfig;

  ChatData({required this.id, required this.name, required this.platform, required this.swearwordsConfig});
}

class ChatEntity extends Entity {
  ChatEntity({required super.dbConnection}) : super(entityName: 'chat');

  Future<int> createChat(String id, String name, String platform) {
    return executeTransaction(queriesMap['create_chat'], {'chatId': id, 'name': name, 'platform': platform});
  }

  Future<List<String>> getAllChatIds(String platform) async {
    var ids = await executeQuery(queriesMap['get_all_chat_ids'], {'platform': platform});

    if (ids == null || ids.isEmpty) {
      return [];
    }

    return ids.map((rawId) => rawId[0].toString()).toList();
  }

  Future<List<ChatData>> getAllChats() async {
    var chats = await executeQuery(queriesMap['get_all_chats']);

    if (chats == null || chats.isEmpty) {
      return [];
    }

    return chats
        .map((chat) => ChatData(id: chat[0], name: chat[1], platform: ChatPlatform.fromString(chat[2]), swearwordsConfig: chat[3]))
        .toList();
  }
}
