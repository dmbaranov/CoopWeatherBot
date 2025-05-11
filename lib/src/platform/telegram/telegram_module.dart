import 'dart:async';

import 'package:teledart/model.dart' hide User, Chat;
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/modules/youtube/youtube.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/modules_mediator.dart';

class TelegramModule {
  final TeleDart bot;
  final Telegram telegram;
  final Platform platform;
  final ModulesMediator modulesMediator;
  final Config _config;

  TelegramModule({required this.bot, required this.telegram, required this.platform, required this.modulesMediator})
      : _config = getIt<Config>();

  void initialize() {}

  void bullyTagUser(TeleDartMessage message) async {
    // just an original feature of this bot that will stay here forever
    var denisId = '354903232';
    var messageAuthorId = message.from?.id.toString();
    var chatId = message.chat.id.toString();

    if (messageAuthorId == _config.adminId) {
      await platform.sendMessage(chatId, message: '@daimonil');
    } else if (messageAuthorId == denisId) {
      await platform.sendMessage(chatId, message: '@dmbaranov_io');
    }
  }

  Future<void> searchYoutubeTrackInline(TeleDartInlineQuery query) async {
    var searchResults = await modulesMediator.get<Youtube>().getRawYoutubeSearchResults(query.query);
    List items = searchResults['items'];
    var inlineQueryResult = [];

    items.forEach((searchResult) {
      var videoId = searchResult['id']['videoId'];
      var videoData = searchResult['snippet'];
      var videoUrl = 'https://www.youtube.com/watch?v=$videoId';

      inlineQueryResult.add(InlineQueryResultVideo(
          id: videoId,
          title: videoData['title'],
          thumbnailUrl: videoData['thumbnails']['high']['url'],
          mimeType: 'video/mp4',
          videoDuration: 600,
          videoUrl: videoUrl,
          inputMessageContent: InputTextMessageContent(messageText: videoUrl, disableWebPagePreview: false)));
    });

    await bot.answerInlineQuery(query.id, [...inlineQueryResult], cacheTime: 10);
  }
}
