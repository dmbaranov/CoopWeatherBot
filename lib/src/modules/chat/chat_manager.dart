import 'package:weather/src/core/chat_config.dart';
import 'package:weather/src/core/messaging.dart';
import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/modules/chat/chat_messaging.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/globals/message_event.dart';
import 'chat.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class ChatManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final Chat _chat;
  final ChatConfig _chatConfig;

  ChatManager(this.platform, this.modulesMediator)
      : _chat = Chat(chatPlatform: platform.chatPlatform),
        _chatConfig = getIt<ChatConfig>();

  @override
  Chat get module => _chat;

  @override
  void initialize() {
    _subscribeToMessageQueue();
    _subscribeToChatConfigUpdatedQueue();
  }

  @override
  void setupCommands() {
    // TODO: see if original message can be removed straight away
    platform.setupCommand(BotCommand(
        command: 'write',
        description: '[M] Write message to the chat on behalf of the bot',
        accessLevel: AccessLevel.moderator,
        withParameters: true,
        onSuccess: _writeToChat));
  }

  void _writeToChat(MessageEvent event) {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var message = event.parameters.join(' ');

    sendOperationMessage(chatId, platform: platform, operationResult: message.isNotEmpty, successfulMessage: message);
  }

  void _subscribeToMessageQueue() {
    MessagingQueue<MessageQueueEvent>().createStream(messageQueue, MessageQueueEvent.fromJson).then((stream) {
      stream.listen((event) {
        platform.sendMessage(event.chatId, message: event.message);
      });
    });
  }

  void _subscribeToChatConfigUpdatedQueue() {
    MessagingQueue<ChatConfigUpdateEvent>().createStream(chatConfigUpdateQueue, ChatConfigUpdateEvent.fromJson).then((stream) {
      stream.listen((event) {
        _chatConfig.updateChatConfig(event.chatId);
      });
    });
  }
}
