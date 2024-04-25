import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'dadjokes.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class DadJokesManager {
  final Platform platform;
  final ModulesMediator modulesMediator;
  final DadJokes _dadjokes;

  DadJokesManager({required this.platform, required this.modulesMediator}) : _dadjokes = DadJokes();

  void initialize() {
    modulesMediator.registerModule(_dadjokes);
  }

  void sendJoke(MessageEvent event) async {
    var chatId = event.chatId;
    var joke = await _dadjokes.getJoke();

    sendOperationMessage(chatId, platform: platform, operationResult: joke.joke.isNotEmpty, successfulMessage: joke.joke);
  }
}
