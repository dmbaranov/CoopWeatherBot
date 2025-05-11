import 'package:weather/src/core/chat_config.dart';
import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
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
  final ChatConfig _chatConfig;

  PanoramaManager(this.platform, this.modulesMediator)
      : _logger = getIt<Logger>(),
        _chatConfig = getIt<ChatConfig>(),
        _panoramaNews = PanoramaNews();

  @override
  PanoramaNews get module => _panoramaNews;

  @override
  void initialize() {
    _panoramaNews.initialize();
    _subscribeToPanoramaNews();
  }

  @override
  void setupCommands() {
    platform.setupCommand(BotCommand(
        command: 'sendnews', description: '[U] Send news to the chat', accessLevel: AccessLevel.user, onSuccess: _sendNewsToChat));
  }

  void _sendNewsToChat(MessageEvent event) async {
    var chatId = event.chatId;
    var news = await _panoramaNews.getNews(chatId);
    var successfulMessage = '${news?.title}\n\nFull: ${news?.url}';

    sendOperationMessage(chatId, platform: platform, operationResult: news != null, successfulMessage: successfulMessage);
  }

  void _subscribeToPanoramaNews() {
    _panoramaNews.panoramaStream.listen((event) async {
      _logger.i('Handling Panorama stream data: $event');

      var allChats = await modulesMediator.chat.getAllChatIdsForPlatform(platform.chatPlatform);

      allChats.forEach((chatId) {
        var newsConfig = _chatConfig.getNewsConfig(chatId);
        var fakeEvent = MessageEvent(chatId: chatId, userId: '', parameters: [], rawMessage: '');

        if (newsConfig?.disabled == true) {
          return;
        }

        _sendNewsToChat(fakeEvent);
      });
    });
  }
}
