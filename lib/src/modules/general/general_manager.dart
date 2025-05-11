import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/globals/message_event.dart';
import 'general.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class GeneralManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final General _general;

  GeneralManager(this.platform, this.modulesMediator) : _general = General();

  @override
  General get module => _general;

  @override
  void initialize() {}

  @override
  void setupCommands() {
    platform.setupCommand(
        BotCommand(command: 'na', description: '[U] Check if bot is alive', accessLevel: AccessLevel.user, onSuccess: _postHealthCheck));

    platform.setupCommand(BotCommand(
        command: 'updatemessage', description: '[A] Post update message', accessLevel: AccessLevel.admin, onSuccess: _postUpdateMessage));
  }

  void _postHealthCheck(MessageEvent event) {
    var chatId = event.chatId;
    var result = _general.healthCheck(chatId);

    sendOperationMessage(chatId, platform: platform, operationResult: result.isNotEmpty, successfulMessage: result);
  }

  void _postUpdateMessage(MessageEvent event) async {
    var chatId = event.chatId;
    var result = await _general.getLastCommitMessage();

    sendOperationMessage(chatId, platform: platform, operationResult: result.isNotEmpty, successfulMessage: result);
  }
}
