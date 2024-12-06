const messageQueue = 'message';

class MessageQueueEvent {
  final String chatId;
  final String message;

  MessageQueueEvent.fromJson(Map<dynamic, dynamic> json)
      : chatId = json['chatId'],
        message = json['message'];
}
