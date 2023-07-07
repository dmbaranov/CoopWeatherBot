import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/command.dart';
import 'package:weather/src/modules/commands_manager.dart';

import 'package:weather/src/platform/platform.dart';

class TelegramPlatform<T extends TeleDartMessage> implements Platform<T> {
  final ChatPlatform chatPlatform = ChatPlatform.telegram;
  final String token;

  late TeleDart bot;
  late Telegram telegram;

  TelegramPlatform({required this.token});

  @override
  Future<void> initializePlatform() async {
    var botName = (await Telegram(token).getMe()).username;

    telegram = Telegram(token);
    bot = TeleDart(token, Event(botName!), fetcher: LongPolling(Telegram(token), limit: 100, timeout: 50));

    bot.start();

    print('Telegram platform has been started!');
  }

  @override
  void setupPlatformSpecificCommands(CommandsManager cm) {
    var accordionCommand = Command(
        command: 'accordion',
        description: 'Start vote for the freshness of the content',
        wrapper: cm.userCommand,
        successCallback: _startTelegramAccordionPoll);

    setupCommand(accordionCommand);
  }

  @override
  Future<void> postStart() async {
    print('No post-start instructions for Telegram');
  }

  @override
  MessageEvent transformPlatformMessageToGeneralMessageEvent(TeleDartMessage event) {
    return MessageEvent(
        platform: ChatPlatform.telegram,
        chatId: event.chat.id.toString(),
        userId: event.from?.id.toString() ?? '',
        isBot: event.replyToMessage?.from?.isBot ?? false,
        otherUserIds: [],
        parameters: [],
        rawMessage: event);
  }

  @override
  void setupCommand(Command command) {
    bot.onCommand(command.command).listen(
        (event) => command.wrapper(transformPlatformMessageToGeneralMessageEvent(event), onSuccess: command.successCallback, onFailure: () {
              print('no_access_message');
            }));
  }

  @override
  Future<void> sendMessage(String chatId, String message) async {
    await telegram.sendMessage(chatId, message);
  }

  void _startTelegramAccordionPoll(MessageEvent event) {
    print('running accordion poll');
  }
}
