import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'conversator.dart';
import '../modules_mediator.dart';
import '../utils.dart';

// TODO: move from here to platform
Map<ChatPlatform, int> responseLimits = {ChatPlatform.telegram: 4000, ChatPlatform.discord: 2000};

class ConversatorManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final Conversator _conversator;

  ConversatorManager(this.platform, this.modulesMediator) : _conversator = Conversator();

  @override
  Conversator get module => _conversator;

  @override
  void initialize() {
    _conversator.initialize();
  }

  @override
  void setupCommands() {
    platform.setupCommand(BotCommand(
        command: 'ask',
        description: '[U] Ask for advice or anything else from the Conversator',
        accessLevel: AccessLevel.user,
        conversatorCommand: true,
        onSuccess: (event) => _getConversatorReply(event, regularModel)));

    platform.setupCommand(BotCommand(
        command: 'theask',
        description: '[U][Limited] Ask for advice or anything else from the more advanced Conversator',
        accessLevel: AccessLevel.user,
        conversatorCommand: true,
        onSuccess: (event) => _getConversatorReply(event, advancedModel)));
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

      var conversatorResponseMessage = await _sendConversatorResponseMessage(chatId, response);
      var conversatorResponseMessageId = platform.getMessageId(conversatorResponseMessage);
      var conversationId = await _conversator.getConversationId(chatId, parentMessageId);

      await _conversator.saveConversationMessage(
          chatId: chatId,
          conversationId: conversationId,
          currentMessageId: conversatorResponseMessageId,
          message: response,
          fromUser: false);
    } catch (error) {
      handleException<ConversatorException>(error, chatId, platform);
    }
  }

  Future _sendConversatorResponseMessage(String chatId, String response) async {
    var responseLimit = responseLimits[platform.chatPlatform]!;
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
