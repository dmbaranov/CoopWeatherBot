import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:cron/cron.dart';
import 'database-manager/database_manager.dart';

class OpenWeatherData {
  final String city;
  final num temp;

  OpenWeatherData(this.city, this.temp);
}

class ChatWeatherData {
  final String chatId;
  final List<OpenWeatherData> weatherData;

  ChatWeatherData({required this.chatId, required this.weatherData});
}

class OpenWeather {
  final String apiKey;
  final String _apiBaseUrl = 'https://api.openweathermap.org/data/2.5';

  OpenWeather(this.apiKey);

  Future<OpenWeatherData> getCurrentWeather(String city) async {
    var url = '$_apiBaseUrl/weather?q=$city&appid=$apiKey&units=metric';

    var request = await io.HttpClient().getUrl(Uri.parse(url));
    var response = await request.close();
    var rawResponse = '';

    await for (var contents in response.transform(Utf8Decoder())) {
      rawResponse += contents;
    }

    var responseJson = json.decode(rawResponse);

    return OpenWeatherData(responseJson['name'], responseJson['main']['temp']);
  }
}

class WeatherManager {
  final DatabaseManager dbManager;
  final String openweatherKey;
  late OpenWeather _openWeather;
  late StreamController<ChatWeatherData> _weatherStreamController;
  List<ScheduledTask> _weatherCronTasks = [];

  WeatherManager({required this.dbManager, required this.openweatherKey});

  Stream<ChatWeatherData> get weatherStream => _weatherStreamController.stream;

  Future<void> initialize() async {
    _openWeather = OpenWeather(openweatherKey);
    _weatherStreamController = StreamController<ChatWeatherData>.broadcast();

    await _updateWeatherStream();
  }

  Future<bool> createWeatherData(String chatId) async {
    var defaultNotificationHour = 7;
    var result = await dbManager.weather.createWeatherData(chatId, defaultNotificationHour);

    return result == 1;
  }

  Future<bool> addCity(String chatId, String city) async {
    var chatCities = await dbManager.weather.getCities(chatId) ?? [];

    if (chatCities.contains(city)) {
      return false;
    }

    List<String> updatedCitiesList = List.from(chatCities)..add(city);

    var updateResult = await dbManager.weather.updateCities(chatId, updatedCitiesList);

    return updateResult == 1;
  }

  Future<bool> removeCity(String chatId, String city) async {
    var chatCities = await dbManager.weather.getCities(chatId) ?? [];

    if (!chatCities.contains(city)) {
      return false;
    }

    List<String> updatedCitiesList = chatCities.where((existingCity) => existingCity != city).toList();

    var updateResult = await dbManager.weather.updateCities(chatId, updatedCitiesList);

    return updateResult == 1;
  }

  Future<List<String>> getWatchList(String chatId) async {
    var cities = await dbManager.weather.getCities(chatId);

    return cities ?? [];
  }

  Future<num?> getWeatherForCity(String city) async {
    try {
      var weatherData = await _openWeather.getCurrentWeather(city);

      return weatherData.temp;
    } catch (err) {
      print(err);

      return null;
    }
  }

  Future<bool> setNotificationHour(String chatId, int notificationHour) async {
    if (notificationHour >= 0 && notificationHour <= 23) {
      var updateResult = await dbManager.weather.setNotificationHour(chatId, notificationHour);

      await _updateWeatherStream();

      return updateResult == 1;
    }

    return false;
  }

  Future<void> _updateWeatherStream() async {
    var notificationHoursForChats = await dbManager.weather.getNotificationHours();

    await Future.forEach(_weatherCronTasks, (task) async => await task.cancel());

    _weatherCronTasks = notificationHoursForChats
        .map((config) => Cron().schedule(Schedule.parse('0 ${config.notificationHour} * * *'), () async {
              var cities = await dbManager.weather.getCities(config.chatId);

              if (cities != null) {
                var weatherData = await _getWeatherForCities(cities);

                _weatherStreamController.sink.add(ChatWeatherData(chatId: config.chatId, weatherData: weatherData));
              }
            }))
        .toList();
  }

  Future<List<OpenWeatherData>> _getWeatherForCities(List<String> cities) async {
    List<OpenWeatherData> result = [];

    await Future.forEach(cities, (city) async {
      try {
        var weather = await _openWeather.getCurrentWeather(city);

        result.add(OpenWeatherData(weather.city, weather.temp));

        await Future.delayed(Duration(milliseconds: 500));
      } catch (err) {
        print("Can't get weather for city $city");
      }
    });

    return result;
  }
}
