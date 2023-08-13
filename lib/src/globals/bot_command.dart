import 'message_event.dart';

typedef BotCommandWrapper = void Function(MessageEvent event,
    {required Function onFailure, Function? onSuccess, Function? onSuccessCustom});
typedef OnSuccessCallback = void Function(MessageEvent event);

class BotCommand {
  final String command;
  final String description;
  final BotCommandWrapper wrapper;
  final bool withParameters;
  final bool withOtherUserIds;
  final bool conversatorCommand;
  final OnSuccessCallback successCallback;

  BotCommand(
      {required this.command,
      required this.description,
      required this.wrapper,
      required this.successCallback,
      this.withParameters = false,
      this.withOtherUserIds = false,
      this.conversatorCommand = false});
}
