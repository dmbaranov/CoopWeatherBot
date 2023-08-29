import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/conversator.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import './utils.dart';

class ConversatorManager {
  final Platform platform;
  final Database db;
  final String conversatorApiKey;
  final Conversator _conversator;

  ConversatorManager({required this.platform, required this.db, required this.conversatorApiKey})
      : _conversator = Conversator(db: db, conversatorApiKey: conversatorApiKey);

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

    try {
      var response = await _conversator.getConversationReply(
          chatId: chatId,
          userId: userId,
          parentMessageId: parentMessageId,
          currentMessageId: currentMessageId,
          message: message,
          model: model);

      var conversatorResponseMessage = await platform.sendMessage(chatId, message: response);
      var conversatorResponseMessageId = platform.getMessageId(conversatorResponseMessage);
      var conversationId = await _conversator.getConversationId(chatId, parentMessageId);

      await _conversator.saveConversationMessage(
          chatId: chatId,
          conversationId: conversationId,
          currentMessageId: conversatorResponseMessageId,
          message: response,
          fromUser: false);
    } catch (err) {
      var errorMessage = err.toString();

      if (errorMessage.startsWith('conversator')) {
        platform.sendMessage(chatId, translation: errorMessage);
      } else {
        platform.sendMessage(chatId, translation: 'general.something_went_wrong');
      }
    }
  }
}
