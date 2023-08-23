import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/panorama.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/utils.dart';

class PanoramaManager {
  final Platform platform;
  final Chat chat;
  final Database db;
  final PanoramaNews _panoramaNews;

  PanoramaManager({required this.platform, required this.chat, required this.db}) : _panoramaNews = PanoramaNews(db: db);

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

    var panoramaStream = _panoramaNews.panoramaStream;

    panoramaStream.listen((event) async {
      var allChats = await chat.getAllChatIdsForPlatform(ChatPlatform.telegram);

      allChats.forEach((chatId) {
        var fakeEvent = MessageEvent(
            platform: ChatPlatform.telegram, chatId: chatId, userId: '', isBot: false, otherUserIds: [], parameters: [], rawMessage: '');

        sendNewsToChat(fakeEvent);
      });
    });
  }
}
