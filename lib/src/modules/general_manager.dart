import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/general.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/utils.dart';
import 'package:weather/src/utils/logger.dart';

class GeneralManager {
  final Platform platform;
  final Chat chat;
  final String repositoryUrl;
  final Logger _logger;
  final General _general;

  GeneralManager({required this.platform, required this.chat, required this.repositoryUrl})
      : _logger = getIt<Logger>(),
        _general = General(chat: chat, repositoryUrl: repositoryUrl);

  void postHealthCheck(MessageEvent event) {
    _logger.i('Sending health check: $event');

    var chatId = event.chatId;
    var result = _general.healthCheck(chatId);

    sendOperationMessage(chatId, platform: platform, operationResult: result.isNotEmpty, successfulMessage: result);
  }

  void postUpdateMessage(MessageEvent event) async {
    _logger.i('Sending update message: $event');

    var chatId = event.chatId;
    var result = await _general.getLastCommitMessage();

    sendOperationMessage(chatId, platform: platform, operationResult: result.isNotEmpty, successfulMessage: result);
  }
}
