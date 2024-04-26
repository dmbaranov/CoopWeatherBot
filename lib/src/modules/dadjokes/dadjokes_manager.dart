import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/globals/message_event.dart';
import 'dadjokes.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class DadJokesManager implements ModuleManager {
  final Platform platform;
  final ModulesMediator modulesMediator;
  final DadJokes _dadJokes;

  DadJokesManager({required this.platform, required this.modulesMediator}) : _dadJokes = DadJokes();

  @override
  DadJokes get module => _dadJokes;

  @override
  void initialize() {}

  void sendJoke(MessageEvent event) async {
    var chatId = event.chatId;
    var joke = await _dadJokes.getJoke();

    sendOperationMessage(chatId, platform: platform, operationResult: joke.joke.isNotEmpty, successfulMessage: joke.joke);
  }
}
