import 'package:teledart/teledart.dart';
import 'package:weather/src/globals/command.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/modules/commands_manager.dart';

import 'package:weather/src/platform/platform.dart';

void setupTelegramSpecificCommands(Platform platform, CommandsManager cm) {
  print('setting up platform-specific commands');
  // bot.onCommand('accordion').listen((event) => cm.use)
  platform.setupCommand(Command(
      command: 'accordion',
      description: 'Start vote for the freshness of the content',
      wrapper: cm.userCommand,
      successCallback: (event) => _startTelegramAccordionPoll(platform, event)));
}

void _startTelegramAccordionPoll(Platform platform, MessageEvent event) async {
  print('running a platform-specific command');
}
