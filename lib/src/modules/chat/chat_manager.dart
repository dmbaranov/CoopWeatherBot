import 'package:weather/src/core/chat_config.dart';
import 'package:weather/src/core/messaging.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/modules/chat/chat_messaging.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/globals/chat_platform.dart';
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
  final Swearwords _sw;
  final ChatConfig _chatConfig;

  ChatManager(this.platform, this.modulesMediator)
      : _chat = Chat(chatPlatform: platform.chatPlatform),
        _sw = getIt<Swearwords>(),
        _chatConfig = getIt<ChatConfig>();

  @override
  Chat get module => _chat;

  @override
  void initialize() {
    _chat.initialize();
    _subscribeToMessageQueue();
    _subscribeToSwearwordsUpdatedQueue();
    _subscribeToChatConfigUpdatedQueue();
  }

  void createChat(MessageEvent event) async {
    var chatId = event.chatId;
    var chatName = _getNewChatName(event);
    var result = await _chat.createChat(id: chatId, name: chatName, platform: platform.chatPlatform);
    var successfulMessage = _sw.getText(chatId, 'chat.initialization.success');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void writeToChat(MessageEvent event) {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var message = event.parameters.join(' ');

    sendOperationMessage(chatId, platform: platform, operationResult: message.isNotEmpty, successfulMessage: message);
  }

  void setSwearwordsConfig(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var config = event.parameters[0];
    var result = await _chat.setSwearwordsConfig(chatId, config);
    var successfulMessage = _sw.getText(chatId, 'general.success');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  String _getNewChatName(MessageEvent event) {
    if (platform.chatPlatform == ChatPlatform.telegram) {
      return event.rawMessage.chat.title.toString();
    } else if (platform.chatPlatform == ChatPlatform.discord) {
      return event.rawMessage.guild.name.toString();
    }

    return 'unknown';
  }

  void _subscribeToMessageQueue() {
    MessagingQueue<MessageQueueEvent>().createStream(messageQueue, MessageQueueEvent.fromJson).then((stream) {
      stream.listen((event) {
        platform.sendMessage(event.chatId, message: event.message);
      });
    });
  }

  void _subscribeToSwearwordsUpdatedQueue() {
    MessagingQueue<SwearwordsUpdatedQueueEvent>().createStream(swearwordsUpdatedQueue, SwearwordsUpdatedQueueEvent.fromJson).then((stream) {
      stream.listen((event) {
        _sw.setChatSwearwords(event.chatId, event.swearwordsConfig);
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
