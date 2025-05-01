import 'package:collection/collection.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/utils/logger.dart';

bool messageEventParametersCheck(Platform platform, MessageEvent event, [int numberOfParameters = 1]) {
  if (event.parameters.whereNot((parameter) => parameter.isEmpty).length < numberOfParameters) {
    platform.sendMessage(event.chatId, translation: 'general.something_went_wrong');

    return false;
  }

  return true;
}

bool otherUserCheck(Platform platform, MessageEvent event) {
  if (event.otherUser == null || event.otherUser?.isBot == true) {
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

void handleException<CustomException>(error, String chatId, Platform platform) {
  getIt<Logger>().e('Handling module exception: $error');

  var errorMessage = CustomException != dynamic && error is CustomException ? error.toString() : 'general.something_went_wrong';
  platform.sendMessage(chatId, translation: errorMessage);
}
