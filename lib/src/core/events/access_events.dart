import 'package:weather/src/core/user.dart';

class AccessEvent {
  final String chatId;
  final BotUser user;
  final String command;

  AccessEvent({required this.chatId, required this.user, required this.command});
}
