import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'general.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class GeneralManager {
  final Platform platform;
  final ModulesMediator modulesMediator;
  final General _general;

  GeneralManager({required this.platform, required this.modulesMediator}) : _general = General();

  void initialize() {
    modulesMediator.registerModule(_general);
  }

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
