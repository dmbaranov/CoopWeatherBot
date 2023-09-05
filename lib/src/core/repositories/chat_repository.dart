import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/core/chat.dart' show ChatData;
import 'repository.dart';

class ChatRepository extends Repository {
  ChatRepository({required super.dbConnection}) : super(repositoryName: 'chat');

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

  Future<int> setChatSwearwordsConfig(String chatId, String config) {
    return executeTransaction(queriesMap['set_swearwords_config'], {'chatId': chatId, 'config': config});
  }
}
