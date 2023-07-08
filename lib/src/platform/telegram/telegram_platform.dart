import 'package:teledart/model.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/command.dart';
import 'package:weather/src/modules/commands_manager.dart';

import 'package:weather/src/platform/platform.dart';

class TelegramPlatform<T extends TeleDartMessage> implements Platform<T> {
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
    print('Telegram platform has been started!');
  }

  @override
  MessageEvent transformPlatformMessageToGeneralMessageEvent(TeleDartMessage message) {
    return MessageEvent(
        platform: ChatPlatform.telegram,
        chatId: message.chat.id.toString(),
        userId: message.from?.id.toString() ?? '',
        isBot: message.replyToMessage?.from?.isBot ?? false,
        otherUserIds: [],
        parameters: [],
        rawMessage: message);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithParameters(TeleDartMessage message) {
    List<String> parameters = message.text?.split(' ').sublist(1).toList() ?? [];

    return transformPlatformMessageToGeneralMessageEvent(message)..parameters.addAll(parameters);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithOtherUserIds(TeleDartMessage event) {
    return transformPlatformMessageToGeneralMessageEvent(event)
      ..otherUserIds.add(event.replyToMessage?.from?.id.toString() ?? '')
      ..parameters.addAll(_getUserInfo(event));
  }

  @override
  MessageEvent transformPlatformMessageToConversatorMessageEvent(TeleDartMessage event) {
    var currentMessageId = event.messageId.toString();
    var parentMessageId = event.replyToMessage?.messageId.toString() ?? currentMessageId;
    var message = event.text?.split(' ').sublist(1).join(' ') ?? '';

    return transformPlatformMessageToGeneralMessageEvent(event)..parameters.addAll([parentMessageId, currentMessageId, message]);
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

  @override
  Future<bool> getUserPremiumStatus(String chatId, String userId) async {
    var telegramUser = await telegram.getChatMember(chatId, int.parse(userId));

    return telegramUser.user.isPremium ?? false;
  }

  void _startTelegramAccordionPoll(MessageEvent event) {
    print('running accordion poll');
  }

  List<String> _getUserInfo(TeleDartMessage message) {
    var fullUsername = '';
    var repliedUser = message.replyToMessage?.from;

    if (repliedUser == null) {
      return [];
    }

    fullUsername += repliedUser.firstName;

    if (repliedUser.username != null) {
      fullUsername += ' <${repliedUser.username}> ';
    }

    fullUsername += repliedUser.lastName ?? '';

    return [fullUsername, repliedUser.isPremium?.toString() ?? 'false'];
  }
}
