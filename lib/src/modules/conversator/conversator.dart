import 'dart:convert';
import 'package:cron/cron.dart';
import 'package:http/http.dart' as http;
import 'package:weather/src/core/chat_config.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/repositories/conversator_chat_repository.dart';
import 'package:weather/src/core/repositories/conversator_user_repository.dart';
import 'package:weather/src/globals/conversator_chat_message.dart';
import 'package:weather/src/globals/module_exception.dart';
import 'package:weather/src/utils/logger.dart';

const String _converstorApiURL = 'https://api.openai.com/v1/chat/completions';
const String regularModel = 'gpt-4.1-mini';
const String advancedModel = 'gpt-4.1';
const int regularDailyLimit = 100;
const int advancedDailyLimit = 10;

class ConversatorException extends ModuleException {
  ConversatorException(super.cause);
}

class Conversator {
  final Config _config;
  final Logger _logger;
  final String _apiBaseUrl = _converstorApiURL;
  final ChatConfig _chatConfig;
  final ConversatorChatRepository _conversatorChatDb;
  final ConversatorUserRepository _conversatorUserDb;

  Conversator()
      : _config = getIt<Config>(),
        _chatConfig = getIt<ChatConfig>(),
        _conversatorChatDb = getIt<ConversatorChatRepository>(),
        _conversatorUserDb = getIt<ConversatorUserRepository>(),
        _logger = getIt<Logger>();

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
    var conversatorConfig = _chatConfig.getConversatorConfig(chatId);

    await _registerConversatorInvocation(userId, model);

    var conversationId = await getConversationId(chatId, parentMessageId);
    var previousMessages = await _conversatorChatDb.getMessagesForConversation(chatId, conversationId);
    await saveConversationMessage(
        chatId: chatId, conversationId: conversationId, currentMessageId: currentMessageId, message: message, fromUser: true);

    var wholeConversation = [...previousMessages, ConversatorChatMessage(message: message, fromUser: true)];

    var rawResponse =
        await _getConversatorResponse(conversation: wholeConversation, model: model, instructions: conversatorConfig?.instructions);
    var response = rawResponse['choices']?[0]?['message']?['content'] ?? 'No response';

    return '# $conversationId\n\n$response';
  }

  Future<void> saveConversationMessage(
      {required String chatId,
      required String conversationId,
      required String currentMessageId,
      required String message,
      required bool fromUser}) async {
    await _conversatorChatDb.createMessage(chatId, conversationId, currentMessageId, message, fromUser);
  }

  Future<String> getConversationId(String chatId, String messageId) async {
    var conversationId = await _conversatorChatDb.findConversationById(chatId, messageId) ?? messageId;

    return conversationId;
  }

  Future<Map<String, dynamic>> _getConversatorResponse(
      {required List<ConversatorChatMessage> conversation, required String model, String? instructions}) async {
    var formattedMessages =
        conversation.map((message) => {'role': message.fromUser ? 'user' : 'assistant', 'content': message.message}).toList();

    if (instructions != null) {
      formattedMessages.insert(0, {'role': 'developer', 'content': instructions});
    }

    var headers = {'Content-Type': 'application/json', 'Authorization': 'Bearer ${_config.conversatorKey}'};
    var body = {'model': model, 'messages': formattedMessages};

    var response =
        await http.post(Uri.parse(_apiBaseUrl), headers: headers, body: json.encode(body), encoding: Encoding.getByName('utf-8'));

    return json.decode(utf8.decode(response.bodyBytes));
  }

  Future<void> _registerConversatorInvocation(String userId, String model) async {
    var conversatorUser = await _conversatorUserDb.getConversatorUser(userId);
    var errorMessage = 'conversator.daily_invocation_limit_hit';

    if (model == regularModel) {
      if (conversatorUser.dailyRegularInvocations >= regularDailyLimit && userId != _config.adminId) {
        throw ConversatorException(errorMessage);
      }

      await _conversatorUserDb.updateRegularInvocations(userId);

      return;
    }

    if (model == advancedModel) {
      if (conversatorUser.dailyAdvancedInvocations >= advancedDailyLimit && userId != _config.adminId) {
        throw ConversatorException(errorMessage);
      }

      await _conversatorUserDb.updateAdvancedInvocations(userId);

      return;
    }
  }

  void _startResetDailyInvocationsUsageJob() {
    Cron().schedule(Schedule.parse('0 0 * * *'), () async {
      var result = await _conversatorUserDb.resetDailyInvocations();

      if (result == 0) {
        _logger.w('Something went wrong with resetting conversator daily invocations usage');
      } else {
        _logger.i('Reset conversator daily invocation usage for $result rows');
      }
    });
  }
}
