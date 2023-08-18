import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';

import '../utils.dart';
import './youtube.dart';

class YoutubeManager {
  final Platform platform;
  final String apiKey;

  final Youtube _youtube;

  YoutubeManager({required this.platform, required this.apiKey}) : _youtube = Youtube(apiKey);

  void searchSong(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var query = event.parameters.join(' ');
    var result = await _youtube.getYoutubeVideoUrl(query);

    sendOperationMessage(chatId, platform: platform, operationResult: result.isNotEmpty, successfulMessage: result);
  }
}
