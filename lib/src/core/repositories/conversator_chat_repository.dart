import '../conversator.dart' show ConversatorChatMessage;
import 'repository.dart';

class ConversatorChatRepository extends Repository {
  ConversatorChatRepository({required super.dbConnection}) : super(repositoryName: 'conversator_chat');

  Future<int> createMessage(String chatId, String conversationId, String messageId, String message, bool fromUser) {
    return executeTransaction(queriesMap['create_message'],
        {'chatId': chatId, 'conversationId': conversationId, 'messageId': messageId, 'message': message, 'fromUser': fromUser});
  }

  Future<List<ConversatorChatMessage>> getMessagesForConversation(String chatId, String conversationId) async {
    var rawChatData = await executeQuery(queriesMap['get_chat_messages'], {'chatId': chatId, 'conversationId': conversationId});

    if (rawChatData == null || rawChatData.isEmpty) {
      return [];
    }

    return rawChatData.map((chatData) => ConversatorChatMessage(message: chatData[0], fromUser: chatData[1])).toList();
  }

  Future<String?> findConversationById(String chatId, String messageId) async {
    var data = await executeQuery(queriesMap['find_conversation'], {'chatId': chatId, 'messageId': messageId});

    if (data == null || data.isEmpty) {
      return null;
    }

    return data[0][0];
  }
}
