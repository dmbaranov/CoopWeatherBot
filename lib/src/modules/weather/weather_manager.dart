import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/utils/logger.dart';
import 'weather.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class WeatherManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final Swearwords _sw;
  final Logger _logger;
  final Weather _weather;

  WeatherManager(this.platform, this.modulesMediator)
      : _logger = getIt<Logger>(),
        _sw = getIt<Swearwords>(),
        _weather = Weather();

  @override
  Weather get module => _weather;

  @override
  void initialize() {
    _weather.initialize();
    _subscribeToWeatherNotifications();
  }

  @override
  void setupCommands() {
    // TODO: change access level to moderator
    platform.setupCommand(BotCommand(
        command: 'createweather',
        description: '[M] Activate weather module for the chat',
        accessLevel: AccessLevel.moderator,
        onSuccess: _createWeather));

    platform.setupCommand(BotCommand(
        command: 'watchlistweather',
        description: '[U] Get weather for each city in the watchlist',
        accessLevel: AccessLevel.user,
        onSuccess: _getWatchlistWeather));

    platform.setupCommand(BotCommand(
        command: 'addcity',
        description: '[U] Add city to the watchlist',
        accessLevel: AccessLevel.user,
        withParameters: true,
        onSuccess: _addCity));

    platform.setupCommand(BotCommand(
        command: 'removecity',
        description: '[U] Remove city from the watchlist',
        accessLevel: AccessLevel.user,
        withParameters: true,
        onSuccess: _removeCity));

    platform.setupCommand(BotCommand(
        command: 'watchlist', description: '[U] Get weather watchlist', accessLevel: AccessLevel.user, onSuccess: _getWeatherWatchlist));

    platform.setupCommand(BotCommand(
        command: 'getweather',
        description: '[U] Get weather for city',
        accessLevel: AccessLevel.user,
        withParameters: true,
        onSuccess: _getWeatherForCity));

    platform.setupCommand(BotCommand(
        command: 'setnotificationhour',
        description: '[M] Set time for weather notifications',
        accessLevel: AccessLevel.moderator,
        withParameters: true,
        onSuccess: _setWeatherNotificationHour));
  }

  void _addCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var cityToAdd = event.parameters[0];
    var result = await _weather.addCity(chatId, cityToAdd);
    var successfulMessage = _sw.getText(chatId, 'weather.cities.added', {'city': cityToAdd});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void _removeCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var cityToRemove = event.parameters[0];
    var result = await _weather.removeCity(chatId, cityToRemove);
    var successfulMessage = _sw.getText(chatId, 'weather.cities.removed', {'city': cityToRemove});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void _getWeatherWatchlist(MessageEvent event) async {
    var chatId = event.chatId;
    var cities = await _weather.getWatchList(chatId);
    var citiesString = cities.join('\n');

    sendOperationMessage(chatId, platform: platform, operationResult: citiesString.isNotEmpty, successfulMessage: citiesString);
  }

  void _getWeatherForCity(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var city = event.parameters[0];

    _weather
        .getWeatherForCity(city)
        .then((result) => sendOperationMessage(chatId,
            platform: platform,
            operationResult: true,
            successfulMessage: _sw.getText(chatId, 'weather.cities.temperature', {'city': city, 'temperature': result.toString()})))
        .catchError((error) => handleException(error, chatId, platform));
  }

  void _setWeatherNotificationHour(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var hour = event.parameters[0];
    var result = await _weather.setNotificationHour(chatId, int.parse(hour));
    var successfulMessage = _sw.getText(chatId, 'weather.other.notification_hour_set', {'hour': hour});

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void _createWeather(MessageEvent event) async {
    var chatId = event.chatId;
    var result = await _weather.createWeatherData(chatId);
    var successfulMessage = _sw.getText(chatId, 'general.success');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void _getWatchlistWeather(MessageEvent event) async {
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

      var chatData = await modulesMediator.chat.getSingleChat(chatId: weatherData.chatId);

      if (chatData?.platform != platform.chatPlatform) {
        return;
      }

      var fakeEvent = MessageEvent(chatId: weatherData.chatId, userId: '', parameters: [], rawMessage: '');

      _getWatchlistWeather(fakeEvent);
    });
  }
}
