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

    var chatId = event.chatId;

    var poll = AccordionPoll2(
        title: _sw.getText(chatId, 'accordion.other.title'), description: _sw.getText(chatId, 'accordion.other.explanation'));
    var pollStarted = poll.startPoll(duration: _accordionPollDuration, options: _translateOptions(chatId));

    if (!pollStarted) {
      throw Exception('__translate__ poll not started');
    }

    var result = await platform.concludePoll(chatId, poll);

    if (result == null) {
      print('poll finished without results');
    } else {
      print('poll result: $result');
    }
  }

  List<String> _translateOptions(String chatId) {
    return _accordionOptions.map<String>((option) => _sw.getText(chatId, option)).toList();
  }
}
