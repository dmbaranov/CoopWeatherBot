const messageQueue = 'chat.message';
const chatConfigUpdateQueue = 'chat-config.updated';

class MessageQueueEvent {
  final String chatId;
  final String message;

  MessageQueueEvent.fromJson(Map<dynamic, dynamic> json)
      : chatId = json['chatId'],
        message = json['message'];
}

class ChatConfigUpdateEvent {
  final String chatId;

  ChatConfigUpdateEvent.fromJson(Map<dynamic, dynamic> json) : chatId = json['chatId'];
}
