import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'youtube.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class YoutubeManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final Youtube _youtube;

  YoutubeManager(this.platform, this.modulesMediator) : _youtube = Youtube();

  @override
  Youtube get module => _youtube;

  @override
  void initialize() {}

  @override
  void setupCommands() {
    platform.setupCommand(BotCommand(
        command: 'searchsong',
        description: '[U] Search song on YouTube',
        accessLevel: AccessLevel.user,
        withParameters: true,
        onSuccess: _searchSong));
  }

  void _searchSong(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var query = event.parameters.join(' ');
    var result = await _youtube.getYoutubeVideoUrl(query);

    sendOperationMessage(chatId, platform: platform, operationResult: result.isNotEmpty, successfulMessage: result);
  }
}
