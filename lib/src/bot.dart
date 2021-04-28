import 'dart:convert';
import 'dart:io' as io;
import 'dart:async';

import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';

import 'openweather.dart';
import 'panorama.dart';
import 'dadjokes.dart';
import 'reputation.dart';

Future sleep(Duration duration) {
  return Future.delayed(duration, () => null);
}

class Bot {
  final String token;
  final int chatId;
  final String repoUrl;
  final int adminId;
  io.File citiesFile;
  TeleDart bot;
  Telegram telegram;
  OpenWeather openWeather;
  DadJokes dadJokes;
  Reputation reputation;
  int notificationHour = 7;

  Bot({this.token, this.chatId, this.repoUrl, this.adminId}) {
    citiesFile = io.File('assets/cities.txt');
  }

  void startBot(String openweatherKey) async {
    telegram = Telegram(token);
    bot = TeleDart(telegram, Event());
    openWeather = OpenWeather(openweatherKey);
    dadJokes = DadJokes();

    await bot.start();

    reputation = Reputation(adminId: adminId, telegram: telegram, chatId: chatId);
    await reputation.initReputation();

    _setupListeners();

    print('Bot has been started!');
  }

  void startNotificationPolling() async {
    var skip = false;

    Timer.periodic(Duration(seconds: 30), (_) async {
      if (skip) return;

      var hour = DateTime.now().hour;

      if (hour == notificationHour) {
        skip = true;

        var cities = await citiesFile.readAsLines();
        var message = '';

        await Future.forEach(cities, (city) async {
          try {
            var data = await openWeather.getCurrentWeather(city);

            message += 'In city ${data.city} the temperature is ${data.temp}°C\n\n';
          } catch (err) {
            print('Error during the notification: $err');
          }
        });

        await telegram.sendMessage(chatId, message);
        await sleep(Duration(hours: 23));

        skip = false;
      }
    });
  }

  void startPanoramaNewsPolling() async {
    await setupPanoramaNews();

    Timer.periodic(Duration(hours: 5, minutes: 41), (_) async {
      var hour = DateTime.now().hour;

      if (hour <= 9 || hour >= 23) return;

      await _sendNewsToChat();
    });
  }

  void startJokesPolling() async {
    Timer.periodic(Duration(hours: 2, minutes: 13), (_) async {
      var hour = DateTime.now().hour;

      if (hour <= 9 || hour >= 23) return;

      await _sendJokeToChat();
    });
  }

  void _setupListeners() {
    bot.onCommand('addcity').listen(_addCity);
    bot.onCommand('removecity').listen(_removeCity);
    bot.onCommand('watchlist').listen(_getWatchlist);
    bot.onCommand('getweather').listen(_getWeatherForCity);
    bot.onCommand('setnotificationhour').listen(_setNotificationHour);
    bot.onCommand('write').listen(_writeToCoop);
    bot.onCommand('ping').listen(_ping);
    bot.onCommand('updatemessage').listen(_postUpdateMessage);
    bot.onCommand('sendnews').listen(_sendNewsToChat);
    bot.onCommand('sendjoke').listen(_sendJokeToChat);
    bot.onCommand('sendrealmusic').listen(_sendRealMusic);
    bot
        .onCommand('increp')
        .listen((TeleDartMessage message) => reputation.updateReputation(message, 'increase'));
    bot
        .onCommand('decrep')
        .listen((TeleDartMessage message) => reputation.updateReputation(message, 'decrease'));
    bot.onCommand('replist').listen(reputation.sendReputationList);
    bot.onCommand('generaterepusers').listen(reputation.generateReputationUsers);

    var bullyTagUserRegexp = RegExp(r'эй\,?\s{0,}хуй$', caseSensitive: false);
    bot.onMessage(keyword: bullyTagUserRegexp).listen(_bullyTagUser);

    var bullyWeatherMessageRegexp = RegExp(r'эй\,?\s{0,}хуй\,?', caseSensitive: false);
    bot.onMessage(keyword: bullyWeatherMessageRegexp).listen(_getBullyWeatherForCity);
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

    var updatedCities =
        cities.where((city) => city != cityToRemove.toLowerCase()).join('\n').toString();

    await citiesFile.writeAsString(updatedCities);

    await message.reply('City $cityToRemove has been removed from the watchlist!');
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

      await message.reply('In city $city the temperature is ${weatherData.temp}°C');
    } catch (err) {
      print(err);

      await message.reply('There was an error processing your request! Try again');
    }
  }

  void _ping(TeleDartMessage message) async {
    // various things to test are here
  }

  void _setNotificationHour(TeleDartMessage message) async {
    var currentHour = notificationHour;
    var nextHourRaw = _getOneParameterFromMessage(message);

    if (nextHourRaw.isEmpty) {
      await message
          .reply('Incorrect value for notification hour. Please use single number from 0 to 23');
      return;
    }

    var nextHour = num.parse(nextHourRaw);

    if (nextHour is int && nextHour >= 0 && nextHour <= 23) {
      notificationHour = nextHour;
      await message.reply('Notification hour has been updated from $currentHour to $nextHour');
      return;
    }

    await message
        .reply('Incorrect value for notification hour. Please use single number from 0 to 23');
  }

  void _getBullyWeatherForCity(TeleDartMessage message) async {
    var messageWords =
        message.text.split(RegExp(r'(,)|(\s{1,})')).where((item) => item.isNotEmpty).toList();

    if (messageWords.length != 3) {
      return;
    }

    var city = messageWords[2];

    try {
      var weatherData = await openWeather.getCurrentWeather(city);

      await message.reply('В дыре $city температура ${weatherData.temp}°C епта');
    } catch (err) {
      print(err);

      await message.reply('Ебобо, там ошибка!');
    }
  }

  void _bullyTagUser(TeleDartMessage message) async {
    var denisId = 354903232;

    if (message.from.id == adminId) {
      await message.reply('@daimonil');
    } else if (message.from.id == denisId) {
      await message.reply('@th1rt3nth');
    }
  }

  void _writeToCoop(TeleDartMessage message) async {
    if (message.text == null) {
      await message.reply('Нахуй пошол, мудило!!1');
      return;
    }

    var rawText = message.text.split(' ');
    var text = rawText.sublist(1).join(' ');

    print('${message.from.toJson()} is writing to Coop: ${message.toJson()}');

    try {
      await telegram.sendMessage(chatId, text);
    } catch (e) {
      await message.reply('Нахуй пошол, мудило!!1');
    }
  }

  String _getOneParameterFromMessage(TeleDartMessage message) {
    var options = message.text.split(' ');

    if (options.length != 2) return '';

    return options[1];
  }

  void _postUpdateMessage(TeleDartMessage message) async {
    var commitsApiUrl = 'https://api.github.com/repos' + repoUrl + '/commits';

    var request = await io.HttpClient().getUrl(Uri.parse(commitsApiUrl));
    var response = await request.close();
    var rawResponse = '';

    await for (var contents in response.transform(Utf8Decoder())) {
      rawResponse += contents;
    }

    var responseJson = json.decode(rawResponse);
    var commitMessage = responseJson[0]['commit']['message'];

    var updateMessage = 'Я проапдейтился, ёпта!\n\nChangelog:\n$commitMessage';

    await telegram.sendMessage(chatId, updateMessage);
  }

  void _sendNewsToChat([TeleDartMessage message]) async {
    var instantViewUrl = 'a.devs.today/';
    var news = await getNews();

    if (news.title.isEmpty) return;

    var message = '${news.title}\n\nFull<a href="${instantViewUrl + news.url}">:</a> ${news.url}';

    await telegram.sendMessage(chatId, message, parse_mode: 'HTML');
  }

  void _sendJokeToChat([TeleDartMessage message]) async {
    var joke = await dadJokes.getJoke();

    await telegram.sendMessage(chatId, joke.joke);
  }
  void _sendRealMusic(TeleDartMessage message) async {
    if (message.text == null || message.text.contains('music.youtube.com') == false) {
      await message.reply('Нахуй пошол, мудило!!1');
      return;
    }

    var rawText = message.text.split(' ');
    var text = rawText.sublist(1).join(' ');
    text = text.replaceAll ('music.', '');

    try {
      await telegram.sendMessage(chatId, text);
    } catch (e) {
      await message.reply('Нахуй пошол, мудило!!1');
    }
  }
}