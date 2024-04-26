import 'dart:async';
import 'dart:math';

import 'package:teledart/model.dart' hide User, Chat;
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/accordion_vote_option.dart';
import 'package:weather/src/modules/modules_mediator.dart';

class TelegramModule {
  final TeleDart bot;
  final Telegram telegram;
  final Platform platform;
  final ModulesMediator modulesMediator;
  final Config _config;
  final Swearwords _sw;

  TelegramModule({required this.bot, required this.telegram, required this.platform, required this.modulesMediator})
      : _config = getIt<Config>(),
        _sw = getIt<Swearwords>();

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

  Future<StreamController<Map<AccordionVoteOption, int>>> startAccordionPoll(String chatId, List<String> pollOptions, int pollTime) async {
    var stream = StreamController<Map<AccordionVoteOption, int>>();

    await telegram.sendPoll(chatId, _sw.getText(chatId, 'accordion.other.title'), pollOptions,
        explanation: _sw.getText(chatId, 'accordion.other.explanation'),
        type: 'quiz',
        correctOptionId: Random().nextInt(pollOptions.length),
        openPeriod: pollTime);

    stream.addStream(bot.onPoll().map((event) => ({
          AccordionVoteOption.yes: event.options[0].voterCount,
          AccordionVoteOption.no: event.options[1].voterCount,
          AccordionVoteOption.maybe: event.options[2].voterCount
        })));

    return stream;
  }

  Future<void> searchYoutubeTrackInline(TeleDartInlineQuery query) async {
    var searchResults = await modulesMediator.youtube.getRawYoutubeSearchResults(query.query);
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
