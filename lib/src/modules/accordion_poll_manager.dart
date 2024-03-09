import 'package:weather/src/core/accordion_poll.dart';
import 'package:weather/src/core/event_bus.dart';
import 'package:weather/src/core/user.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/utils/logger.dart';
import 'utils.dart';

class AccordionPollManager {
  final Platform platform;
  final EventBus eventBus;
  final User user;
  final Chat chat;
  final Logger _logger;
  final AccordionPoll _accordionPoll;

  AccordionPollManager({required this.platform, required this.eventBus, required this.user, required this.chat})
      : _logger = getIt<Logger>(),
        _accordionPoll = AccordionPoll(eventBus: eventBus, chat: chat);

  void startAccordionPoll(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;

    if (event.platform != ChatPlatform.telegram) {
      await platform.sendMessage(event.chatId, translation: 'general.no_access');

      return;
    }

    _logger.i('Starting accordion poll: $event');

    var chatId = event.chatId;
    var fromUser = await user.getSingleUserForChat(chatId, event.userId);
    var toUser = await user.getSingleUserForChat(chatId, event.otherUserIds[0]);
    var pollStartError = _accordionPoll.startPoll(chatId: chatId, fromUser: fromUser, toUser: toUser, isBot: event.isBot);

    if (pollStartError != null) {
      await platform.sendMessage(chatId, translation: pollStartError);

      return;
    }

    var pollStream = await platform.startAccordionPoll(chatId, _accordionPoll.pollOptions, _accordionPoll.pollTime);

    pollStream.stream.listen((pollResults) => _accordionPoll.updatePollResults(pollResults));

    var pollResult = await _accordionPoll.endVoteAndGetResults();

    await platform.sendMessage(chatId, translation: pollResult);
  }
}
