import 'package:weather/src/globals/bot_user.dart';

class AccordionPollEvent {
  final BotUser fromUser;
  final BotUser toUser;
  final String chatId;

  AccordionPollEvent({required this.fromUser, required this.toUser, required this.chatId});
}

class PollCompletedYes extends AccordionPollEvent {
  PollCompletedYes({required super.fromUser, required super.toUser, required super.chatId});
}

class PollCompletedNo extends AccordionPollEvent {
  PollCompletedNo({required super.fromUser, required super.toUser, required super.chatId});
}
