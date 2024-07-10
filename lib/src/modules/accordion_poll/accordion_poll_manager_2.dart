import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/globals/module_exception.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/modules/modules_mediator.dart';
import 'package:weather/src/modules/utils.dart';
import 'accordion_poll_2.dart';

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

    var chatId = event.chatId;

    AccordionPoll2(title: _sw.getText(chatId, 'accordion.other.title'), description: _sw.getText(chatId, 'accordion.other.explanation'))
        .startPoll(chatId: chatId, fromUserId: event.userId, toUserId: event.otherUser!.id)
        .then((poll) => platform.concludePoll(chatId, poll))
        .then((pollResult) =>
            sendOperationMessage(chatId, platform: platform, operationResult: true, successfulMessage: _getSuccessMessage(pollResult)))
        .catchError((error) => handleException(error, chatId, platform));
  }

  String _getSuccessMessage(String? pollResult) {
    return 'poll completed successfully with result $pollResult';
  }
}
