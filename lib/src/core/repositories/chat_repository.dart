import 'package:injectable/injectable.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/chat_data.dart';
import 'repository.dart';

@singleton
class ChatRepository extends Repository {
  ChatRepository({required super.db}) : super(repositoryName: 'chat');

  Future<int> createChat(String id, String name, String platform) {
    return db.executeTransaction(queriesMap['create_chat'], {'chatId': id, 'name': name, 'platform': platform});
  }

  Future<List<String>> getAllChatIds(String platform) async {
    var ids = await db.executeQuery(queriesMap['get_all_chat_ids'], {'platform': platform});

    if (ids == null || ids.isEmpty) {
      return [];
    }

    return ids.map((rawId) => rawId[0].toString()).toList();
  }

  Future<List<ChatData>> getAllChats() async {
    var chats = await db.executeQuery(queriesMap['get_all_chats']);

    if (chats == null || chats.isEmpty) {
      return [];
    }

    return chats.map((chat) => _mapChat(chat.toColumnMap())).toList();
  }

  Future<ChatData?> getSingleChat({required String chatId}) async {
    var chat = await db.executeQuery(queriesMap['get_single_chat'], {'chatId': chatId});

    if (chat == null || chat.isEmpty) {
      return null;
    }

    return _mapChat(chat[0].toColumnMap());
  }

  ChatData _mapChat(Map<String, dynamic> foundChat) {
    return ChatData(id: foundChat['id'], name: foundChat['name'], platform: ChatPlatform.fromString(foundChat['platform']));
  }
}
