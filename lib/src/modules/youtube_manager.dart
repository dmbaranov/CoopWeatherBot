import 'package:weather/src/core/youtube.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/utils/logger.dart';
import 'utils.dart';

class YoutubeManager {
  final Platform platform;
  final String apiKey;
  final Logger _logger;
  final Youtube _youtube;

  YoutubeManager({required this.platform, required this.apiKey})
      : _logger = getIt<Logger>(),
        _youtube = Youtube(apiKey);

  void searchSong(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    _logger.i('Searching for a song: $event');

    var chatId = event.chatId;
    var query = event.parameters.join(' ');
    var result = await _youtube.getYoutubeVideoUrl(query);

    sendOperationMessage(chatId, platform: platform, operationResult: result.isNotEmpty, successfulMessage: result);
  }
}
