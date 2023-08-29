import 'dart:convert';
import 'package:http/http.dart' as http;
import './database.dart';

const String _converstorApiURL = 'https://api.openai.com/v1/chat/completions';
const int maxTokens = 4096;
const String regularModel = 'gpt-3.5-turbo';
const String advancedModel = 'gpt-4';
const int regularDailyLimit = 100;
const int advancedDailyLimit = 10;

class ConversatorChatMessage {
  final String message;
  final bool fromUser;

  ConversatorChatMessage({required this.message, required this.fromUser});
}

class ConversatorUser {
  final String id;
  final int dailyRegularInvocations;
  final int totalRegularInvocations;
  final int dailyAdvancedInvocations;
  final int totalAdvancedInvocations;

  ConversatorUser(
      {required this.id,
      required this.dailyRegularInvocations,
      required this.totalRegularInvocations,
      required this.dailyAdvancedInvocations,
      required this.totalAdvancedInvocations});
}

class Conversator {
  final Database db;
  final String conversatorApiKey;
  final String _apiBaseUrl = _converstorApiURL;

  Conversator({required this.db, required this.conversatorApiKey});

  Future<String> getConversationReply(
      {required String userId,
      required String chatId,
      required String parentMessageId,
      required String currentMessageId,
      required String message,
      required String model}) async {
    await _registerConversatorInvocation(userId, model);

    var conversationId = await getConversationId(chatId, parentMessageId);
    var previousMessages = await db.conversatorChat.getMessagesForConversation(chatId, conversationId);
    await saveConversationMessage(
        chatId: chatId, conversationId: conversationId, currentMessageId: currentMessageId, message: message, fromUser: true);

    var wholeConversation = [...previousMessages, ConversatorChatMessage(message: message, fromUser: true)];

    var rawResponse = await _getConversatorResponse(wholeConversation, model);
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

  Future<Map<String, dynamic>> _getConversatorResponse(List<ConversatorChatMessage> conversation, String model) async {
    var formattedMessages =
        conversation.map((message) => {'role': message.fromUser ? 'user' : 'system', 'content': message.message}).toList();

    var headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer $conversatorApiKey'};
    var body = {'model': model, 'messages': formattedMessages};

    var response =
        await http.post(Uri.parse(_apiBaseUrl), headers: headers, body: json.encode(body), encoding: Encoding.getByName('utf-8'));

    return json.decode(utf8.decode(response.bodyBytes));
  }

  Future<void> _registerConversatorInvocation(String userId, String model) async {
    var conversatorUser = await db.conversatorUser.getConversatorUser(userId);

    if (model == regularModel) {
      if (conversatorUser.dailyRegularInvocations > regularDailyLimit) {
        throw Exception('Daily regular limit exceeded');
      }

      await db.conversatorUser.updateRegularInvocations(userId);

      return;
    }

    if (model == advancedModel) {
      if (conversatorUser.dailyAdvancedInvocations > advancedDailyLimit) {
        throw Exception('Daily advanced limit exceeded');
      }

      await db.conversatorUser.updateAdvancedInvocations(userId);

      return;
    }
  }
}
