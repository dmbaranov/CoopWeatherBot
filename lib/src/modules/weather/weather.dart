import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cron/cron.dart';

import 'package:weather/src/core/database.dart';

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

class Weather {
  final Database db;
  final String openweatherKey;
  final String _apiBaseUrl = 'https://api.openweathermap.org/data/2.5';

  late StreamController<ChatWeatherData> _weatherStreamController;
  List<ScheduledTask> _weatherCronTasks = [];

  Weather({required this.db, required this.openweatherKey});

  Stream<ChatWeatherData> get weatherStream => _weatherStreamController.stream;

  Future<void> initialize() async {
    _weatherStreamController = StreamController<ChatWeatherData>.broadcast();

    await _updateWeatherStream();
  }

  Future<bool> createWeatherData(String chatId) async {
    var defaultNotificationHour = 7;
    var result = await db.weather.createWeatherData(chatId, defaultNotificationHour);

    return result == 1;
  }

  Future<bool> addCity(String chatId, String city) async {
    var chatCities = await db.weather.getCities(chatId) ?? [];

    if (chatCities.contains(city)) {
      return false;
    }

    var updatedCitiesList = List<String>.from(chatCities)..add(city);
    var updateResult = await db.weather.updateCities(chatId, updatedCitiesList);

    return updateResult == 1;
  }

  Future<bool> removeCity(String chatId, String city) async {
    var chatCities = await db.weather.getCities(chatId) ?? [];

    if (!chatCities.contains(city)) {
      return false;
    }

    var updatedCitiesList = chatCities.where((existingCity) => existingCity != city).toList();
    var updateResult = await db.weather.updateCities(chatId, updatedCitiesList);

    return updateResult == 1;
  }

  Future<List<String>> getWatchList(String chatId) async {
    var cities = await db.weather.getCities(chatId);

    return cities ?? [];
  }

  Future<num?> getWeatherForCity(String city) async {
    try {
      var weatherData = await _getCurrentWeather(city);

      return weatherData.temp;
    } catch (err) {
      print(err);

      return null;
    }
  }

  Future<bool> setNotificationHour(String chatId, int notificationHour) async {
    if (notificationHour >= 0 && notificationHour <= 23) {
      var updateResult = await db.weather.setNotificationHour(chatId, notificationHour);

      await _updateWeatherStream();

      return updateResult == 1;
    }

    return false;
  }

  Future<OpenWeatherData> _getCurrentWeather(String city) async {
    var url = '$_apiBaseUrl/weather?q=$city&appid=$openweatherKey&units=metric';

    var response = await http.get(Uri.parse(url));
    var responseJson = jsonDecode(response.body);

    return OpenWeatherData(responseJson['name'], responseJson['main']['temp']);
  }

  Future<void> _updateWeatherStream() async {
    var notificationHoursForChats = await db.weather.getNotificationHours();

    await Future.forEach(_weatherCronTasks, (task) async => await task.cancel());

    _weatherCronTasks = notificationHoursForChats
        .map((config) => Cron().schedule(Schedule.parse('0 ${config.notificationHour} * * *'), () async {
              var cities = await db.weather.getCities(config.chatId);

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
        var weather = await _getCurrentWeather(city);

        result.add(OpenWeatherData(weather.city, weather.temp));

        await Future.delayed(Duration(milliseconds: 500));
      } catch (err) {
        print("Can't get weather for city $city");
      }
    });

    return result;
  }
}
