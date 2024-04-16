import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'youtube.dart';
import '../utils.dart';

class YoutubeManager {
  final Platform platform;
  final Youtube _youtube;

  YoutubeManager({required this.platform}) : _youtube = Youtube();

  void searchSong(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var query = event.parameters.join(' ');
    var result = await _youtube.getYoutubeVideoUrl(query);

    sendOperationMessage(chatId, platform: platform, operationResult: result.isNotEmpty, successfulMessage: result);
  }
}
