import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/weather.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/utils/logger.dart';
import 'utils.dart';

class WeatherManager {
  final Platform platform;
  final Chat chat;
  final Database db;
  final String openweatherKey;
  final Logger _logger;
  final Weather _weather;

  WeatherManager({required this.platform, required this.chat, required this.db, required this.openweatherKey})
      : _logger = getIt<Logger>(),
        _weather = Weather(db: db, openweatherKey: openweatherKey);

  void initialize() {
    _weather.initialize();

    _subscribeToWeatherNotifications();
  }

  void addCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;
    _logger.i('Adding a new city: $event');

    var chatId = event.chatId;
    var cityToAdd = event.parameters[0];
    var result = await _weather.addCity(chatId, cityToAdd);
    var successfulMessage = chat.getText(chatId, 'weather.cities.added', {'city': cityToAdd});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void removeCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;
    _logger.i('Removing city: $event');

    var chatId = event.chatId;
    var cityToRemove = event.parameters[0];
    var result = await _weather.removeCity(chatId, cityToRemove);
    var successfulMessage = chat.getText(chatId, 'weather.cities.removed', {'city': cityToRemove});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void getWeatherWatchlist(MessageEvent event) async {
    _logger.i('Getting a weather watchlist: $event');

    var chatId = event.chatId;
    var cities = await _weather.getWatchList(chatId);
    var citiesString = cities.join('\n');

    sendOperationMessage(chatId, platform: platform, operationResult: citiesString.isNotEmpty, successfulMessage: citiesString);
  }

  void getWeatherForCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;
    _logger.i('Getting weather for city: $event');

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
    _logger.i('Setting weather notification hour: $event');

    var chatId = event.chatId;
    var hour = event.parameters[0];
    var result = await _weather.setNotificationHour(chatId, int.parse(hour));
    var successfulMessage = chat.getText(chatId, 'weather.other.notification_hour_set', {'hour': hour});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void createWeather(MessageEvent event) async {
    _logger.i('Creating weather data: $event');

    var chatId = event.chatId;
    var result = await _weather.createWeatherData(chatId);
    var successfulMessage = chat.getText(chatId, 'general.success');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void getWatchlistWeather(MessageEvent event) async {
    _logger.i('Getting watchlist weather: $event');

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
