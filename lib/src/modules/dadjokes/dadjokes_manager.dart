import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/modules/utils.dart';
import 'package:weather/src/platform/platform.dart';
import './dadjokes.dart';

class DadJokesManager {
  final Platform platform;

  late DadJokes _dadjokes;

  DadJokesManager({required this.platform}) : _dadjokes = DadJokes();

  void sendJoke(MessageEvent event) async {
    var chatId = event.chatId;
    var joke = await _dadjokes.getJoke();

    sendOperationMessage(chatId, platform: platform, operationResult: joke.joke.isNotEmpty, successfulMessage: joke.joke);
  }
}
