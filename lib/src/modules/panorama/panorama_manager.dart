import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/chat_manager.dart';
import 'package:weather/src/modules/database-manager/database_manager.dart';

import './panorama.dart';

class PanoramaManager {
  final Platform platform;
  final ChatManager chatManager;
  final DatabaseManager dbManager;

  late PanoramaNews _panoramaNews;

  PanoramaManager({required this.platform, required this.chatManager, required this.dbManager}) {
    _panoramaNews = PanoramaNews(dbManager: dbManager);
  }

  void initialize() {
    _panoramaNews.initialize();
    _subscribeToPanoramaNews();
  }

  void sendNewsToChat(MessageEvent event) async {
    var chatId = event.chatId;
    var news = await _panoramaNews.getNews(chatId);

    if (news != null) {
      var newsMessage = '${news.title}\n\nFull: ${news.url}';

      await platform.sendMessage(chatId, message: newsMessage);
    } else {
      await platform.sendMessage(chatId, translation: 'general.something_went_wrong');
    }
  }

  // TODO: add news_enabled flag and send news to all the enabled chats
  void _subscribeToPanoramaNews() {
    var panoramaStream = _panoramaNews.panoramaStream;

    panoramaStream.listen((event) async {
      var allChats = await chatManager.getAllChatIdsForPlatform(ChatPlatform.telegram);

      allChats.forEach((chatId) {
        var fakeEvent = MessageEvent(
            platform: ChatPlatform.telegram, chatId: chatId, userId: '', isBot: false, otherUserIds: [], parameters: [], rawMessage: '');

        sendNewsToChat(fakeEvent);
      });
    });
  }
}
