import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'accordion_poll.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class AccordionPollManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final AccordionPoll _accordionPoll;

  AccordionPollManager(this.platform, this.modulesMediator) : _accordionPoll = AccordionPoll();

  @override
  AccordionPoll get module => _accordionPoll;

  @override
  void initialize() {}

  void startAccordionPoll(MessageEvent event) async {
    if (!otherUserCheck(platform, event)) return;

    if (event.platform != ChatPlatform.telegram) {
      await platform.sendMessage(event.chatId, translation: 'general.no_access');

      return;
    }

    var chatId = event.chatId;
    var fromUser = await modulesMediator.user.getSingleUserForChat(chatId, event.userId);
    var toUser = await modulesMediator.user.getSingleUserForChat(chatId, event.otherUser!.id);
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
