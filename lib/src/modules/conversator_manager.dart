import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/conversator.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'utils.dart';

class ConversatorManager {
  final Platform platform;
  final Database db;
  final String conversatorApiKey;
  final String adminId;
  final Conversator _conversator;

  ConversatorManager({required this.platform, required this.db, required this.conversatorApiKey, required this.adminId})
      : _conversator = Conversator(db: db, conversatorApiKey: conversatorApiKey, adminId: adminId);

  void initialize() {
    _conversator.initialize();
  }

  void getRegularConversatorReply(MessageEvent event) {
    _getConversatorReply(event, regularModel);
  }

  void getAdvancedConversatorReply(MessageEvent event) {
    _getConversatorReply(event, advancedModel);
  }

  void _getConversatorReply(MessageEvent event, String model) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.userId;
    var parentMessageId = event.parameters[0];
    var currentMessageId = event.parameters[1];
    var message = event.parameters[2];
    var responseLimit = platform.chatPlatform == ChatPlatform.discord ? 2000 : null;

    try {
      var response = await _conversator.getConversationReply(
          chatId: chatId,
          userId: userId,
          parentMessageId: parentMessageId,
          currentMessageId: currentMessageId,
          message: message,
          model: model);

      var conversatorResponseMessage = await _sendConversatorResponseMessage(chatId, response, responseLimit);
      var conversatorResponseMessageId = platform.getMessageId(conversatorResponseMessage);
      var conversationId = await _conversator.getConversationId(chatId, parentMessageId);

      await _conversator.saveConversationMessage(
          chatId: chatId,
          conversationId: conversationId,
          currentMessageId: conversatorResponseMessageId,
          message: response,
          fromUser: false);
    } catch (err) {
      var errorMessage = err.toString().substring(11); // delete Exception:

      if (errorMessage.startsWith('conversator')) {
        platform.sendMessage(chatId, translation: errorMessage);
      } else {
        platform.sendMessage(chatId, translation: 'general.no_access');
      }
    }
  }

  Future _sendConversatorResponseMessage(String chatId, String response, int? responseLimit) async {
    if (responseLimit == null) {
      return platform.sendMessage(chatId, message: response);
    }

    var messages = _splitResponseToParts(response, responseLimit);
    var sentMessage;

    await Future.forEach(messages, (message) async {
      await Future.delayed(Duration(milliseconds: 500));

      sentMessage = await platform.sendMessage(chatId, message: message);
    });

    return sentMessage;
  }

  List<String> _splitResponseToParts(String response, int responseLimit) {
    List<String> messageParts = [];
    var regexRule = '(.|\\n|\\r){1,$responseLimit}';

    for (var part in RegExp(regexRule).allMatches(response)) {
      var message = part[0];

      if (message != null) {
        messageParts.add(message);
      }
    }

    return messageParts;
  }
}
