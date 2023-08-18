import 'package:weather/src/core/database.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import '../utils.dart';
import './conversator.dart';

class ConversatorManager {
  final Platform platform;
  final Database db;
  final String conversatorApiKey;
  final Conversator _conversator;

  ConversatorManager({required this.platform, required this.db, required this.conversatorApiKey})
      : _conversator = Conversator(db: db, conversatorApiKey: conversatorApiKey);

  void getConversationReply(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var parentMessageId = event.parameters[0];
    var currentMessageId = event.parameters[1];
    var message = event.parameters[2];

    var response = await _conversator.getConversationReply(
        chatId: chatId, parentMessageId: parentMessageId, currentMessageId: currentMessageId, message: message);

    var conversatorResponseMessage = await platform.sendMessage(chatId, message: response);
    var conversatorResponseMessageId = platform.getMessageId(conversatorResponseMessage);
    var conversationId = await _conversator.getConversationId(chatId, parentMessageId);

    await _conversator.saveConversationMessage(
        chatId: chatId, conversationId: conversationId, currentMessageId: conversatorResponseMessageId, message: response, fromUser: false);
  }
}
