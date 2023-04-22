import 'dart:convert';
import 'package:http/http.dart';
import 'package:weather/src/modules/database-manager/database_manager.dart';
import 'package:weather/src/modules/database-manager/entities/conversator_chat_entity.dart';

const String _converstorApiURL = 'https://api.openai.com/v1/chat/completions';
const String _conversatorModel = 'gpt-3.5-turbo';

class Conversator {
  final DatabaseManager dbManager;
  final String conversatorApiKey;
  final String _apiBaseUrl = _converstorApiURL;
  final String _model = _conversatorModel;

  Conversator({required this.dbManager, required this.conversatorApiKey});

  Future<String> getConversationReply(
      {required String chatId, required String parentMessageId, required String currentMessageId, required String message}) async {
    var conversationId = await getConversationId(chatId, parentMessageId);
    var previousMessages = await dbManager.conversatorChat.getMessagesForConversation(chatId, conversationId);
    await saveConversationMessage(
        chatId: chatId, conversationId: conversationId, currentMessageId: currentMessageId, message: message, fromUser: true);

    var response = await _getConversatorResponse(previousMessages, message);

    return response['choices']?[0]?['message']?['content'] ?? 'No response';
  }

  Future<String> getSingleReply(String question) async {
    var response = await _getConversatorResponse([], question);

    return response['choices']?[0]?['message']?['content'] ?? 'No response';
  }

  Future<void> saveConversationMessage(
      {required String chatId,
      required String conversationId,
      required String currentMessageId,
      required String message,
      required bool fromUser}) async {
    await dbManager.conversatorChat.createMessage(chatId, conversationId, currentMessageId, message, fromUser);
  }

  Future<String> getConversationId(String chatId, String messageId) async {
    var conversationId = await dbManager.conversatorChat.findConversationById(chatId, messageId) ?? messageId;

    return conversationId;
  }

  Future<Map<String, dynamic>> _getConversatorResponse(List<ConversatorChatMessage> previousMessages, String question) async {
    var formattedMessages = previousMessages
        .map((message) => {'role': message.fromUser ? 'user' : 'system', 'content': message.message})
        .toList()
      ..add({'role': 'user', 'content': question});

    var headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $conversatorApiKey'};
    var body = {'model': _model, 'messages': formattedMessages};

    var response = await post(Uri.parse(_apiBaseUrl), headers: headers, body: json.encode(body), encoding: Encoding.getByName('utf-8'));

    return json.decode(utf8.decode(response.bodyBytes));
  }
}
