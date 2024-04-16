import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/chat/chat.dart';
import 'package:weather/src/utils/logger.dart';
import 'panorama.dart';
import '../utils.dart';

class PanoramaManager {
  final Platform platform;
  final Chat chat;
  final Logger _logger;
  final PanoramaNews _panoramaNews;

  PanoramaManager({required this.platform, required this.chat})
      : _logger = getIt<Logger>(),
        _panoramaNews = PanoramaNews();

  void initialize() {
    _panoramaNews.initialize();
    _subscribeToPanoramaNews();
  }

  void sendNewsToChat(MessageEvent event) async {
    var chatId = event.chatId;
    var news = await _panoramaNews.getNews(chatId);
    var successfulMessage = '${news?.title}\n\nFull: ${news?.url}';

    sendOperationMessage(chatId, platform: platform, operationResult: news != null, successfulMessage: successfulMessage);
  }

  // TODO: add news_enabled flag and send news to all the enabled chats
  void _subscribeToPanoramaNews() {
    if (platform.chatPlatform != ChatPlatform.telegram) {
      return;
    }

    _panoramaNews.panoramaStream.listen((event) async {
      _logger.i('Handling Panorama stream data: $event');

      var allChats = await chat.getAllChatIdsForPlatform(ChatPlatform.telegram);

      allChats.forEach((chatId) {
        var fakeEvent = MessageEvent(
            platform: ChatPlatform.telegram, chatId: chatId, userId: '', isBot: false, otherUserIds: [], parameters: [], rawMessage: '');

        sendNewsToChat(fakeEvent);
      });
    });
  }
}
