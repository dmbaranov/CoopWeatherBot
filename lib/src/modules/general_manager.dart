import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/general.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/utils.dart';

class GeneralManager {
  final Platform platform;
  final Chat chat;
  final String repositoryUrl;
  final General _general;

  GeneralManager({required this.platform, required this.chat, required this.repositoryUrl})
      : _general = General(chat: chat, repositoryUrl: repositoryUrl);

  void postHealthCheck(MessageEvent event) {
    var chatId = event.chatId;
    var result = _general.healthCheck(chatId);

    sendOperationMessage(chatId, platform: platform, operationResult: result.isNotEmpty, successfulMessage: result);
  }

  void postUpdateMessage(MessageEvent event) async {
    var chatId = event.chatId;
    var result = await _general.getLastCommitMessage();

    sendOperationMessage(chatId, platform: platform, operationResult: result.isNotEmpty, successfulMessage: result);
  }
}
