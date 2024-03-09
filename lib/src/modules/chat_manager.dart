import 'package:weather/src/core/chat.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/utils/logger.dart';

import 'utils.dart';

class ChatManager {
  final Platform platform;
  final Chat chat;
  final Logger _logger;

  ChatManager({required this.platform, required this.chat}) : _logger = getIt<Logger>();

  void createChat(MessageEvent event) async {
    _logger.i('Creating chat: $event');

    var chatId = event.chatId;
    var chatName = _getNewChatName(event);
    var result = await chat.createChat(id: chatId, name: chatName, platform: event.platform);
    var successfulMessage = chat.getText(chatId, 'chat.initialization.success');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void writeToChat(MessageEvent event) {
    if (!messageEventParametersCheck(platform, event)) return;

    _logger.i('Writing to chat: $event');

    var chatId = event.chatId;
    var message = event.parameters.join(' ');

    sendOperationMessage(chatId, platform: platform, operationResult: message.isNotEmpty, successfulMessage: message);
  }

  void setSwearwordsConfig(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    _logger.i('Setting swearwords config: $event');

    var chatId = event.chatId;
    var config = event.parameters[0];
    var result = await chat.setSwearwordsConfig(chatId, config);
    var successfulMessage = chat.getText(chatId, 'general.success');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  String _getNewChatName(MessageEvent event) {
    if (event.platform == ChatPlatform.telegram) {
      return event.rawMessage.chat.title.toString();
    } else if (event.platform == ChatPlatform.discord) {
      return event.rawMessage.guild.name.toString();
    }

    return 'unknown';
  }
}
