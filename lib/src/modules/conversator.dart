import 'dart:convert';
import 'package:http/http.dart';
import 'package:weather/src/modules/database-manager/database_manager.dart';

const String _converstorApiURL = 'https://api.openai.com/v1/chat/completions';
const String _conversatorModel = 'gpt-3.5-turbo-0301';

class Conversator {
  final DatabaseManager dbManager;
  final String conversatorApiKey;
  final String _apiBaseUrl = _converstorApiURL;
  final String _model = _conversatorModel;

  Conversator({required this.dbManager, required this.conversatorApiKey});

  Future<String> getConversationReply(
      {required String chatId, required String parentMessageId, required String currentMessageId, required String message}) async {
    var conversationId = await getConversationId(chatId, parentMessageId);
    await saveConversationMessage(
        chatId: chatId, conversationId: conversationId, currentMessageId: currentMessageId, message: message, fromUser: true);

    var response = 'hardcoded response';
    return response;
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

  Future<Map<String, dynamic>> _getConversatorResponse(String question) async {
    var headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $conversatorApiKey'};
    var body = {
      'model': _model,
      'messages': [
        {'role': 'user', 'content': question}
      ]
    };

    var response = await post(Uri.parse(_apiBaseUrl), headers: headers, body: json.encode(body), encoding: Encoding.getByName('utf-8'));

    return json.decode(utf8.decode(response.bodyBytes));
  }
}
