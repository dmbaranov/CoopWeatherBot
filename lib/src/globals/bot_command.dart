import 'message_event.dart';
import 'access_level.dart';

typedef OnSuccessCallback = void Function(MessageEvent event);

class BotCommand {
  final String command;
  final String description;
  final AccessLevel accessLevel;
  final OnSuccessCallback onSuccess;
  final bool withParameters;
  final bool withOtherUser;
  final bool conversatorCommand;

  BotCommand(
      {required this.command,
      required this.description,
      required this.accessLevel,
      required this.onSuccess,
      this.withParameters = false,
      this.withOtherUser = false,
      this.conversatorCommand = false});
}
