const messageQueue = 'chat-message';
const swearwordsUpdatedQueue = 'chat-swearwords-updated';
const chatConfigUpdateQueue = 'chat-config-updated';

class MessageQueueEvent {
  final String chatId;
  final String message;

  MessageQueueEvent.fromJson(Map<dynamic, dynamic> json)
      : chatId = json['chatId'],
        message = json['message'];
}

class SwearwordsUpdatedQueueEvent {
  final String chatId;
  final String swearwordsConfig;

  SwearwordsUpdatedQueueEvent.fromJson(Map<dynamic, dynamic> json)
      : chatId = json['chatId'],
        swearwordsConfig = json['swearwordsConfig'];
}

class ChatConfigUpdateEvent {
  final String chatId;

  ChatConfigUpdateEvent.fromJson(Map<dynamic, dynamic> json) : chatId = json['chatId'];
}
