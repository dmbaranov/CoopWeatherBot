import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/globals/module_exception.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/modules/modules_mediator.dart';
import 'package:weather/src/modules/utils.dart';
import 'accordion_poll_2.dart';

const _accordionPollDuration = Duration(seconds: 180);
const _accordionOptions = [
  'accordion.options.yes',
  'accordion.options.no',
  'accordion.options.maybe',
];

class AccordionPollException extends ModuleException {
  AccordionPollException(super.cause);
}

class AccordionPollManager2 implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final Swearwords _sw;

  AccordionPollManager2(this.platform, this.modulesMediator) : _sw = getIt<Swearwords>();

  @override
  get module => null;

  @override
  void initialize() {}

  void startAccordionPoll(MessageEvent event) async {
    if (!otherUserCheck(platform, event)) return;

    // TODO: it should be simple, with minimum logic. move all logic to accordion_poll_2
    var chatId = event.chatId;

    // TODO: move options to accordion_poll_2, use accordion_vote_option
    AccordionPoll2(title: _sw.getText(chatId, 'accordion.other.title'), description: _sw.getText(chatId, 'accordion.other.explanation'))
        .startPoll(
            duration: _accordionPollDuration, options: _translateOptions(chatId), fromUserId: event.userId, toUserId: event.otherUser!.id)
        .then((poll) => platform.concludePoll(chatId, poll))
        .then((pollResult) =>
            sendOperationMessage(chatId, platform: platform, operationResult: true, successfulMessage: _getSuccessMessage(pollResult)))
        .catchError((error) => handleException(error, chatId, platform));

    // var poll = AccordionPoll2(
    //     title: _sw.getText(chatId, 'accordion.other.title'), description: _sw.getText(chatId, 'accordion.other.explanation'));
    // var pollStarted = poll.startPoll(duration: _accordionPollDuration, options: _translateOptions(chatId));
    //
    // if (!pollStarted) {
    //   throw Exception('__translate__ poll not started');
    // }
    //
    // var result = await platform.concludePoll(chatId, poll);
    //
    // if (result == null) {
    //   print('poll finished without results');
    // } else {
    //   print('poll result: $result');
    // }
  }

  List<String> _translateOptions(String chatId) {
    return _accordionOptions.map<String>((option) => _sw.getText(chatId, option)).toList();
  }

  String _getSuccessMessage(String? pollResult) {
    return 'poll completed successfully with result $pollResult';
  }
}
