class AccordionPollEvent {
  final String fromUserId;
  final String toUserId;
  final String chatId;

  AccordionPollEvent({required this.fromUserId, required this.toUserId, required this.chatId});
}

class PollCompletedYes extends AccordionPollEvent {
  PollCompletedYes({required super.fromUserId, required super.toUserId, required super.chatId});
}

class PollCompletedNo extends AccordionPollEvent {
  PollCompletedNo({required super.fromUserId, required super.toUserId, required super.chatId});
}
