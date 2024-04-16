import 'package:injectable/injectable.dart';
import 'package:weather/src/globals/conversator_chat_message.dart';
import 'repository.dart';

@singleton
class ConversatorChatRepository extends Repository {
  ConversatorChatRepository({required super.db}) : super(repositoryName: 'conversator_chat');

  Future<int> createMessage(String chatId, String conversationId, String messageId, String message, bool fromUser) {
    return db.executeTransaction(queriesMap['create_message'],
        {'chatId': chatId, 'conversationId': conversationId, 'messageId': messageId, 'message': message, 'fromUser': fromUser});
  }

  Future<List<ConversatorChatMessage>> getMessagesForConversation(String chatId, String conversationId) async {
    var rawChatData = await db.executeQuery(queriesMap['get_chat_messages'], {'chatId': chatId, 'conversationId': conversationId});

    if (rawChatData == null || rawChatData.isEmpty) {
      return [];
    }

    return rawChatData
        .map((chatData) => chatData.toColumnMap())
        .map((chatData) => ConversatorChatMessage(message: chatData['message'], fromUser: chatData['from_user']))
        .toList();
  }

  Future<String?> findConversationById(String chatId, String messageId) async {
    var data = await db.executeQuery(queriesMap['find_conversation'], {'chatId': chatId, 'messageId': messageId});

    if (data == null || data.isEmpty) {
      return null;
    }

    return data[0][0].toString();
  }
}
