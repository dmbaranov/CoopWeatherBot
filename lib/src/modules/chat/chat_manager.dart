import 'dart:io';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/chat.dart';

import '../utils.dart';

class ChatManager {
  final Platform platform;
  final Database db;

  late Chat _chat;

  ChatManager({required this.platform, required this.db}) {
    _chat = Chat(db: db);
  }

  Future<void> initialize() async {
    await _chat.initialize();
  }

  void createChat(MessageEvent event) async {
    var chatId = event.chatId;
    var chatName = _getNewChatName(event);
    var result = await _chat.createChat(id: chatId, name: chatName, platform: event.platform);
    var successfulMessage = _chat.getText(chatId, 'chat.initialization.success');

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
