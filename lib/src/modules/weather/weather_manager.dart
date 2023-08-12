import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/chat_manager.dart';

import '../utils.dart';
import './weather.dart';

class WeatherManager {
  final Platform platform;
  final ChatManager chatManager;
  final Weather weather;

  WeatherManager({required this.platform, required this.chatManager, required this.weather});

  void addCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var cityToAdd = event.parameters[0];
    var result = await weather.addCity(chatId, cityToAdd);
    var successfulMessage = chatManager.getText(chatId, 'weather.cities.added', {'city': cityToAdd});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void removeCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var cityToRemove = event.parameters[0];
    var result = await weather.removeCity(chatId, cityToRemove);
    var successfulMessage = chatManager.getText(chatId, 'weather.cities.removed', {'city': cityToRemove});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }
}
