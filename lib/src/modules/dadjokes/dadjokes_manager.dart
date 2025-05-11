import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/globals/message_event.dart';
import 'dadjokes.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class DadJokesManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final DadJokes _dadJokes;

  DadJokesManager(this.platform, this.modulesMediator) : _dadJokes = DadJokes();

  @override
  DadJokes get module => _dadJokes;

  @override
  void initialize() {}

  @override
  void setupCommands() {
    platform.setupCommand(
        BotCommand(command: 'sendjoke', description: '[U] Send joke to the chat', accessLevel: AccessLevel.user, onSuccess: _sendJoke));
  }

  void _sendJoke(MessageEvent event) async {
    var chatId = event.chatId;
    var joke = await _dadJokes.getJoke();

    sendOperationMessage(chatId, platform: platform, operationResult: joke.joke.isNotEmpty, successfulMessage: joke.joke);
  }
}
