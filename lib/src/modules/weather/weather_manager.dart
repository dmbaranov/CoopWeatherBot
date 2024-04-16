import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/modules/chat/chat.dart';
import 'package:weather/src/utils/logger.dart';
import 'weather.dart';
import '../utils.dart';

class WeatherManager {
  final Platform platform;
  final Chat chat;
  final String openweatherKey;
  final Logger _logger;
  final Weather _weather;

  WeatherManager({required this.platform, required this.chat, required this.openweatherKey})
      : _logger = getIt<Logger>(),
        _weather = Weather(openweatherKey: openweatherKey);

  void initialize() {
    _weather.initialize();

    _subscribeToWeatherNotifications();
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

    sendOperationMessage(chatId, platform: platform, operationResult: citiesString.isNotEmpty, successfulMessage: citiesString);
  }

  void getWeatherForCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var city = event.parameters[0];

    _weather
        .getWeatherForCity(city)
        .then((result) => sendOperationMessage(chatId,
            platform: platform,
            operationResult: true,
            successfulMessage: chat.getText(chatId, 'weather.cities.temperature', {'city': city, 'temperature': result.toString()})))
        .catchError((error) => handleException(error, chatId, platform));
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

  void getWatchlistWeather(MessageEvent event) async {
    var chatId = event.chatId;

    _weather
        .getWatchList(chatId)
        .then((watchlistCities) => _weather.getWeatherForCities(watchlistCities))
        .then((weatherData) => sendOperationMessage(chatId,
            platform: platform, operationResult: true, successfulMessage: _buildWatchlistWeatherMessage(weatherData)))
        .catchError((error) => handleException(error, chatId, platform));
  }

  String _buildWatchlistWeatherMessage(List<OpenWeatherData> weatherData) {
    return weatherData.map((data) => 'In city: ${data.city} the temperature is ${data.temp}\n\n').join();
  }

  void _subscribeToWeatherNotifications() {
    _weather.weatherStream.listen((weatherData) async {
      _logger.i('Handling weather notification data: $weatherData');

      var chatData = await chat.getSingleChat(chatId: weatherData.chatId);

      if (chatData?.platform != platform.chatPlatform) {
        return;
      }

      var fakeEvent = MessageEvent(
          platform: platform.chatPlatform,
          chatId: weatherData.chatId,
          userId: '',
          isBot: false,
          otherUserIds: [],
          parameters: [],
          rawMessage: '');

      getWatchlistWeather(fakeEvent);
    });
  }
}
