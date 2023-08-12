import 'package:collection/collection.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';

bool messageEventParametersCheck(Platform platform, MessageEvent event, [int numberOfParameters = 1]) {
  if (event.parameters.whereNot((parameter) => parameter.isEmpty).length < numberOfParameters) {
    platform.sendMessage(event.chatId, translation: 'general.something_went_wrong');

    return false;
  }

  return true;
}

bool userIdsCheck(Platform platform, MessageEvent event, [int numberOfIds = 1]) {
  if (event.parameters.whereNot((parameter) => parameter.isEmpty).length < numberOfIds) {
    platform.sendMessage(event.chatId, translation: 'general.something_went_wrong');

    return false;
  }

  return true;
}

void sendOperationMessage(String chatId, {required Platform platform, required bool operationResult, required String successfulMessage}) {
  if (operationResult) {
    platform.sendMessage(chatId, message: successfulMessage);
  } else {
    platform.sendMessage(chatId, translation: 'general.something_went_wrong');
  }
}
