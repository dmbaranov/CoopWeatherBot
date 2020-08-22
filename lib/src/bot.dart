import 'dart:io' as io;

import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';

class Bot {
  final String token;
  io.File citiesFile;
  TeleDart bot;

  Bot(token) : token = token {
    citiesFile = io.File('assets/cities.txt');
  }

  void startBot() async {
    bot = TeleDart(Telegram(token), Event());

    await bot.start();

    setupListeners();

    print('Bot has been started!');
  }

  void setupListeners() {
    bot.onCommand('addcity').listen(_addCity);
    bot.onCommand('removecity').listen(_removeCity);
  }

  void _addCity(TeleDartMessage message) async {
    var cityToAdd = _getCityFromMessage(message);

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
    var cityToRemove = _getCityFromMessage(message);

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

  String _getCityFromMessage(TeleDartMessage message) {
    var options = message.text.split(' ');

    print('${options}, ${options.length}');

    if (options.length != 2) return '';

    return options[1];
  }
}
