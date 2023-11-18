import 'package:weather/src/core/user.dart';
import 'package:weather/src/globals/chat_platform.dart';

class AccessEvent {
  final BotUser user;
  final String command;
  final ChatPlatform platform;

  AccessEvent({required this.user, required this.command, required this.platform});
}
