import 'package:teledart/teledart.dart';
import 'package:weather/src/globals/command.dart';

import './event_mappers.dart';

void setupTelegramCommand(TeleDart bot, Command command) {
  bot
      .onCommand(command.command)
      .listen((event) => command.wrapper(mapTelegramEventToGeneralMessageEvent(event), onSuccess: command.successCallback, onFailure: () {
            print('no_access_message');
          }));
}
