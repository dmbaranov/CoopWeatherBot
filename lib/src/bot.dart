import 'dart:io' as io;
import 'dart:async';

import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';

import 'openweather.dart';

Future sleep(Duration duration) {
  return Future.delayed(duration, () => null);
}

class Bot {
  final String token;
  io.File citiesFile;
  TeleDart bot;
  Telegram telegram;
  OpenWeather openWeather;
  int notificationHour = 7;

  Bot(token) : token = token {
    citiesFile = io.File('assets/cities.txt');
  }

  void startBot(String openweatherKey) async {
    telegram = Telegram(token);
    bot = TeleDart(telegram, Event());
    openWeather = OpenWeather(openweatherKey);

    await bot.start();

    _setupListeners();

    print('Bot has been started!');
  }

  void startNotificationPolling(int chatId) async {
    var skip = false;

    Timer.periodic(Duration(seconds: 5), (_) async {
      if (skip) return;

      var hour = DateTime.now().hour;

      if (hour == notificationHour) {
        skip = true;

        var cities = await citiesFile.readAsLines();

        await Future.forEach(cities, (city) async {
          try {
            var data = await openWeather.getCurrentWeather(city);

            await telegram.sendMessage(chatId,
                'In city ${data.city} the temperature is ${data.temp}°C');
          } catch (err) {
            print('Error during the notification: $err');
          }
        });

        await sleep(Duration(hours: 23));

        skip = false;
      }
    });
  }

  void _setupListeners() {
    bot.onCommand('addcity').listen(_addCity);
    bot.onCommand('removecity').listen(_removeCity);
    bot.onCommand('watchlist').listen(_getWatchlist);
    bot.onCommand('getweather').listen(_getWeatherForCity);
    bot.onCommand('setnotificationhour').listen(_setNotificationHour);
    bot.onCommand('ping').listen(_ping);
  }

  void _addCity(TeleDartMessage message) async {
    var cityToAdd = _getOneParameterFromMessage(message);

    if (cityToAdd.isEmpty) {
      await message.reply('Provide one city to add!');
      return;
    }

    var cities = await citiesFile.readAsLines();

    if (cities.contains(cityToAdd.toLowerCase())) {
      await message.reply('City $cityToAdd is in the watchlist already!');
      return;
    }

    var updatedCities = cities.map((city) => city.toLowerCase()).toList();
    updatedCities.add(cityToAdd.toLowerCase());

    await citiesFile.writeAsString(updatedCities.join('\n'));

    await message.reply('City $cityToAdd has been added to the watchlist!');
  }

  void _removeCity(TeleDartMessage message) async {
    var cityToRemove = _getOneParameterFromMessage(message);

    if (cityToRemove.isEmpty) {
      await message.reply('Provide one city to remove!');
      return;
    }

    var cities = await citiesFile.readAsLines();

    if (!cities.contains(cityToRemove.toLowerCase())) {
      await message.reply('City $cityToRemove is not in the watchlist!');
      return;
    }

    var updatedCities = cities
        .where((city) => city != cityToRemove.toLowerCase())
        .join('\n')
        .toString();

    await citiesFile.writeAsString(updatedCities);

    await message
        .reply('City $cityToRemove has been removed from the watchlist!');
  }

  void _getWatchlist(TeleDartMessage message) async {
    var cities = await citiesFile.readAsLines();

    if (cities.isEmpty) {
      await message.reply("I'm not watching any cities");
      return;
    }

    var citiesString = cities.join('\n');

    await message.reply("I'm watching these cities:\n$citiesString");
  }

  void _getWeatherForCity(TeleDartMessage message) async {
    var city = _getOneParameterFromMessage(message);

    if (city.isEmpty) {
      await message.reply('Provide a city!');
      return;
    }

    try {
      var weatherData = await openWeather.getCurrentWeather(city);

      await message
          .reply('In city $city the temperature is ${weatherData.temp}°C');
    } catch (err) {
      print(err);

      await message
          .reply('There was an error processing your request! Try again');
    }
  }

  void _ping(TeleDartMessage message) async {
    // various things to test are here
  }

  void _setNotificationHour(TeleDartMessage message) async {
    var currentHour = notificationHour;
    var nextHourRaw = _getOneParameterFromMessage(message);

    if (nextHourRaw.isEmpty) {
      await message.reply(
          'Incorrect value for notification hour. Please use single number from 0 to 23');
      return;
    }

    var nextHour = num.parse(nextHourRaw);

    if (nextHour is int && nextHour >= 0 && nextHour <= 23) {
      notificationHour = nextHour;
      await message.reply(
          'Notification hour has been updated from $currentHour to $nextHour');
      return;
    }

    await message.reply(
        'Incorrect value for notification hour. Please use single number from 0 to 23');
  }

  String _getOneParameterFromMessage(TeleDartMessage message) {
    var options = message.text.split(' ');

    if (options.length != 2) return '';

    return options[1];
  }
}
