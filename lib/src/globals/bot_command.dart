import 'message_event.dart';
import 'access_level.dart';

typedef OnSuccessCallback = void Function(MessageEvent event);

class BotCommand {
  final String command;
  final String description;
  final AccessLevel accessLevel;
  final OnSuccessCallback onSuccess;
  final bool withParameters;
  final bool withOtherUserIds;
  final bool conversatorCommand;
  final bool checkCommand;

  BotCommand(
      {required this.command,
      required this.description,
      required this.accessLevel,
      required this.onSuccess,
      this.withParameters = false,
      this.withOtherUserIds = false,
      this.conversatorCommand = false,
      this.checkCommand = false});
}
