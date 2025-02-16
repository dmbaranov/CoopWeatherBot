const messageQueue = 'chat-message';
const swearwordsUpdatedQueue = 'chat-swearwords-updated';

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
