import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/entities/conversator_chat_entity.dart' show ConversatorChatMessage;

const String _converstorApiURL = 'https://api.openai.com/v1/chat/completions';
const String _conversatorModel = 'gpt-3.5-turbo';
const int maxTokens = 4096;

class Conversator {
  final Database db;
  final String conversatorApiKey;
  final String _apiBaseUrl = _converstorApiURL;
  final String _model = _conversatorModel;

  Conversator({required this.db, required this.conversatorApiKey});

  Future<String> getConversationReply(
      {required String chatId, required String parentMessageId, required String currentMessageId, required String message}) async {
    var conversationId = await getConversationId(chatId, parentMessageId);
    var previousMessages = await db.conversatorChat.getMessagesForConversation(chatId, conversationId);
    await saveConversationMessage(
        chatId: chatId, conversationId: conversationId, currentMessageId: currentMessageId, message: message, fromUser: true);

    var wholeConversation = [...previousMessages, ConversatorChatMessage(message: message, fromUser: true)];

    var rawResponse = await _getConversatorResponse(wholeConversation);
    var response = rawResponse['choices']?[0]?['message']?['content'] ?? 'No response';
    var tokens = rawResponse['usage']?['total_tokens'] ?? -1;

    return '# $conversationId\n($tokens/$maxTokens)\n\n$response';
  }

  Future<void> saveConversationMessage(
      {required String chatId,
      required String conversationId,
      required String currentMessageId,
      required String message,
      required bool fromUser}) async {
    await db.conversatorChat.createMessage(chatId, conversationId, currentMessageId, message, fromUser);
  }

  Future<String> getConversationId(String chatId, String messageId) async {
    var conversationId = await db.conversatorChat.findConversationById(chatId, messageId) ?? messageId;

    return conversationId;
  }

  Future<Map<String, dynamic>> _getConversatorResponse(List<ConversatorChatMessage> conversation) async {
    var formattedMessages =
        conversation.map((message) => {'role': message.fromUser ? 'user' : 'system', 'content': message.message}).toList();

    var headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $conversatorApiKey'};
    var body = {'model': _model, 'messages': formattedMessages};

    var response =
        await http.post(Uri.parse(_apiBaseUrl), headers: headers, body: json.encode(body), encoding: Encoding.getByName('utf-8'));

    return json.decode(utf8.decode(response.bodyBytes));
  }
}