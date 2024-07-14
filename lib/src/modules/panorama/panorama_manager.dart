import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/utils/logger.dart';
import 'panorama.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class PanoramaManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final Logger _logger;
  final PanoramaNews _panoramaNews;

  PanoramaManager(this.platform, this.modulesMediator)
      : _logger = getIt<Logger>(),
        _panoramaNews = PanoramaNews();

  @override
  PanoramaNews get module => _panoramaNews;

  @override
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

      var allChats = await modulesMediator.chat.getAllChatIdsForPlatform(ChatPlatform.telegram);

      allChats.forEach((chatId) {
        var fakeEvent = MessageEvent(chatId: chatId, userId: '', isBot: false, parameters: [], rawMessage: '');

        sendNewsToChat(fakeEvent);
      });
    });
  }
}
