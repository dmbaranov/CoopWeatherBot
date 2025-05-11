import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/module_exception.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/modules/modules_mediator.dart';
import 'package:weather/src/modules/utils.dart';
import 'accordion_poll.dart';

class AccordionPollException extends ModuleException {
  AccordionPollException(super.cause);
}

class AccordionPollManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final Swearwords _sw;

  AccordionPollManager(this.platform, this.modulesMediator) : _sw = getIt<Swearwords>();

  @override
  get module => null;

  @override
  void initialize() {}

  @override
  void setupCommands() {
    platform.setupCommand(BotCommand(
        command: 'accordion',
        description: '[U] Start vote for the freshness of the content',
        accessLevel: AccessLevel.user,
        withOtherUser: true,
        onSuccess: _startAccordionPoll));
  }

  void _startAccordionPoll(MessageEvent event) async {
    if (!otherUserCheck(platform, event)) return;

    var chatId = event.chatId;

    AccordionPoll(title: _sw.getText(chatId, 'accordion.other.title'), description: _sw.getText(chatId, 'accordion.other.explanation'))
        .startPoll(chatId: chatId, fromUserId: event.userId, toUserId: event.otherUser!.id)
        .then((poll) => platform.concludePoll(chatId, poll))
        .then((pollResult) =>
            sendOperationMessage(chatId, platform: platform, operationResult: true, successfulMessage: _sw.getText(chatId, pollResult)))
        .catchError((error) => handleException(error, chatId, platform));
  }
}
