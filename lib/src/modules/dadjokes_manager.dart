import 'package:weather/src/core/dadjokes.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/modules/utils.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/utils/logger.dart';

class DadJokesManager {
  final Platform platform;
  final Logger _logger;
  final DadJokes _dadjokes;

  DadJokesManager({required this.platform})
      : _logger = getIt<Logger>(),
        _dadjokes = DadJokes();

  void sendJoke(MessageEvent event) async {
    _logger.i('Sending a joke: $event');
    
    var chatId = event.chatId;
    var joke = await _dadjokes.getJoke();

    sendOperationMessage(chatId, platform: platform, operationResult: joke.joke.isNotEmpty, successfulMessage: joke.joke);
  }
}
