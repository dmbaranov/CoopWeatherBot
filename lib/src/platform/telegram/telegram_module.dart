import 'dart:async';
import 'dart:math';

import 'package:teledart/model.dart' hide User, Chat;
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:weather/src/globals/accordion_vote_option.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/user/user.dart';

class TelegramModule {
  final TeleDart bot;
  final Telegram telegram;
  final Platform platform;
  final User user;
  final Config _config;
  final Swearwords _sw;

  TelegramModule({required this.bot, required this.telegram, required this.platform, required this.user})
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
}
