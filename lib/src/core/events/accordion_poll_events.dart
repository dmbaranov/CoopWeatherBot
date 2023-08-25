import '../user.dart' show BotUser;

class AccordionPollEvent {
  final BotUser fromUser;
  final BotUser toUser;
  final String chatId;

  AccordionPollEvent({required this.fromUser, required this.toUser, required this.chatId});
}

class PollCompletedYes extends AccordionPollEvent {
  PollCompletedYes({required BotUser fromUser, required BotUser toUser, required String chatId})
      : super(fromUser: fromUser, toUser: toUser, chatId: chatId);
}

class PollCompletedNo extends AccordionPollEvent {
  PollCompletedNo({required BotUser fromUser, required BotUser toUser, required String chatId})
      : super(fromUser: fromUser, toUser: toUser, chatId: chatId);
}
