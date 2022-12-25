import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:cron/cron.dart';

class OpenWeatherData {
  final String city;
  final num temp;

  OpenWeatherData(this.city, this.temp);

  OpenWeatherData.fromJson(Map<String, dynamic> json)
      : city = json['city'],
        temp = json['temp'];

  Map<String, dynamic> toJson() => {'city': city, 'temp': temp};
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
    var rawWeatherData = {'city': responseJson['name'], 'temp': responseJson['main']['temp']};

    return OpenWeatherData.fromJson(rawWeatherData);
  }
}

class Weather {
  final String openweatherKey;
  int _notificationHour = 7;
  late OpenWeather _openWeather;
  late StreamController<String> _weatherStreamController;
  late io.File _citiesFile;
  ScheduledTask? _weatherCronTask;

  Weather({required this.openweatherKey});

  void initWeather() {
    _openWeather = OpenWeather(openweatherKey);
    _citiesFile = io.File('assets/cities.txt');
    _weatherStreamController = StreamController<String>.broadcast();

    _updateWeatherStream();
  }

  Stream<String> get weatherStream => _weatherStreamController.stream;

  Future<bool> addCity(String cityToAdd) async {
    var cities = await _citiesFile.readAsLines();

    if (cities.contains(cityToAdd.toLowerCase()) || cityToAdd.isEmpty) {
      return false;
    }

    var citiesList = cities.map((city) => city.toLowerCase()).toList();
    citiesList.add(cityToAdd.toLowerCase());

    await _citiesFile.writeAsString(citiesList.join('\n'));

    return true;
  }

  Future<bool> removeCity(String cityToRemove) async {
    var cities = await _citiesFile.readAsLines();

    if (!cities.contains(cityToRemove.toLowerCase()) || cityToRemove.isEmpty) {
      return false;
    }

    var updatedCities = cities.where((city) => city != cityToRemove.toLowerCase()).join('\n').toString();

    await _citiesFile.writeAsString(updatedCities);

    return true;
  }

  Future<String> getWatchList() async {
    var cities = await _citiesFile.readAsLines();

    if (cities.isEmpty) return '';

    return cities.join('\n');
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

  bool setNotificationsHour(int nextNotificationHour) {
    if (_notificationHour >= 0 && _notificationHour <= 23) {
      _notificationHour = nextNotificationHour;
      _updateWeatherStream();

      return true;
    }

    return false;
  }

  void _updateWeatherStream() {
    _weatherCronTask?.cancel();

    _weatherCronTask = Cron().schedule(Schedule.parse('0 $_notificationHour * * *'), () async {
      var cities = await _citiesFile.readAsLines();
      var message = '';

      await Future.forEach(cities, (city) async {
        try {
          var data = await _openWeather.getCurrentWeather(city.toString());

          message += 'In city ${data.city} the temperature is ${data.temp}°C\n\n';
        } catch (err) {
          print('Error during the notification: $err');
        }
      });

      _weatherStreamController.sink.add(message);
    });
  }
}
