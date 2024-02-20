import 'dart:convert';
import 'package:cron/cron.dart';
import 'package:http/http.dart' as http;
import 'package:weather/src/globals/module_exception.dart';
import 'database.dart';

const String _converstorApiURL = 'https://api.openai.com/v1/chat/completions';
const int maxTokens = 4096;
const String regularModel = 'gpt-3.5-turbo';
const String advancedModel = 'gpt-4-turbo-preview';
const int regularDailyLimit = 100;
const int advancedDailyLimit = 10;

class ConversatorException extends ModuleException {
  ConversatorException(super.cause);
}

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
  final String adminId;
  final String _apiBaseUrl = _converstorApiURL;

  Conversator({required this.db, required this.conversatorApiKey, required this.adminId});

  void initialize() {
    _startResetDailyInvocationsUsageJob();
  }

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
    var errorMessage = 'conversator.daily_invocation_limit_hit';

    if (model == regularModel) {
      if (conversatorUser.dailyRegularInvocations >= regularDailyLimit && userId != adminId) {
        throw ConversatorException(errorMessage);
      }

      await db.conversatorUser.updateRegularInvocations(userId);

      return;
    }

    if (model == advancedModel) {
      if (conversatorUser.dailyAdvancedInvocations >= advancedDailyLimit && userId != adminId) {
        throw ConversatorException(errorMessage);
      }

      await db.conversatorUser.updateAdvancedInvocations(userId);

      return;
    }
  }

  void _startResetDailyInvocationsUsageJob() {
    Cron().schedule(Schedule.parse('0 0 * * *'), () async {
      var result = await db.conversatorUser.resetDailyInvocations();

      if (result == 0) {
        print('Something went wrong with resetting conversator daily invocations usage');
      } else {
        print('Reset conversator daily invocation usage for $result rows');
      }
    });
  }
}
