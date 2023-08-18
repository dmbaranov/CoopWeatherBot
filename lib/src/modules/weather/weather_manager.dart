import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/chat.dart';

import '../utils.dart';
import './weather.dart';

class WeatherManager {
  final Platform platform;
  final Chat chat;
  final Database db;
  final String openweatherKey;

  late Weather _weather;

  WeatherManager({required this.platform, required this.chat, required this.db, required this.openweatherKey})
      : _weather = Weather(db: db, openweatherKey: openweatherKey);

  Future<void> initialize() async {
    await _weather.initialize();

    _subscribeToWeatherUpdates();
  }

  void addCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var cityToAdd = event.parameters[0];
    var result = await _weather.addCity(chatId, cityToAdd);
    var successfulMessage = chat.getText(chatId, 'weather.cities.added', {'city': cityToAdd});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void removeCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var cityToRemove = event.parameters[0];
    var result = await _weather.removeCity(chatId, cityToRemove);
    var successfulMessage = chat.getText(chatId, 'weather.cities.removed', {'city': cityToRemove});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void getWeatherWatchlist(MessageEvent event) async {
    var chatId = event.chatId;
    var cities = await _weather.getWatchList(chatId);
    var citiesString = cities.join('\n');

    await platform.sendMessage(chatId, message: citiesString);
  }

  void getWeatherForCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var city = event.parameters[0];
    var temperature = await _weather.getWeatherForCity(city);
    var result = temperature != null;
    var successfulMessage = chat.getText(chatId, 'weather.cities.temperature', {'city': city, 'temperature': temperature.toString()});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void setWeatherNotificationHour(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var hour = event.parameters[0];
    var result = await _weather.setNotificationHour(chatId, int.parse(hour));
    var successfulMessage = chat.getText(chatId, 'weather.other.notification_hour_set', {'hour': hour});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void createWeather(MessageEvent event) async {
    var chatId = event.chatId;
    var result = await _weather.createWeatherData(chatId);
    var successfulMessage = chat.getText(chatId, 'general.success');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void _subscribeToWeatherUpdates() {
    var weatherStream = _weather.weatherStream;

    weatherStream.listen((weatherData) {
      var message = '';

      weatherData.weatherData.forEach((weatherData) {
        message += 'In city: ${weatherData.city} the temperature is ${weatherData.temp}\n\n';
      });

      platform.sendMessage(weatherData.chatId, message: message);
    });
  }
}
