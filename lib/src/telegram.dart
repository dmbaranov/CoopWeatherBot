import 'dart:convert';
import 'dart:io' as io;
import 'dart:async';

import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:debounce_throttle/debounce_throttle.dart';

import 'modules/swearwords_manager.dart';
import 'modules/weather.dart';
import 'modules/panorama.dart';
import 'modules/dadjokes.dart';
import 'modules/reputation.dart';
import 'modules/youtube.dart';

class TelegramBot {
  final String token;
  final int chatId;
  final String repoUrl;
  final int adminId;
  final String youtubeKey;
  final String openweatherKey;
  late io.File citiesFile;
  late TeleDart bot;
  late Telegram telegram;
  late SwearwordsManager sm;
  late Weather weather;

  late DadJokes dadJokes;
  late Reputation reputation;
  late Youtube youtube;
  late int notificationHour = 7;
  late Debouncer<TeleDartInlineQuery?> debouncer = Debouncer(Duration(seconds: 1), initialValue: null);

  TelegramBot(
      {required this.token,
      required this.chatId,
      required this.repoUrl,
      required this.adminId,
      required this.youtubeKey,
      required this.openweatherKey});

  void startBot() async {
    final botName = (await Telegram(token).getMe()).username;

    telegram = Telegram(token);
    bot = TeleDart(token, Event(botName!), fetcher: LongPolling(Telegram(token), limit: 100, timeout: 50));
    weather = Weather(openweatherKey: openweatherKey);
    dadJokes = DadJokes();
    youtube = Youtube(youtubeKey);

    citiesFile = io.File('assets/cities.txt');

    bot.start();

    sm = SwearwordsManager();
    await sm.initSwearwords();

    reputation = Reputation(sm: sm);
    await reputation.initReputation();

    _setupListeners();

    print('Bot has been started!');
  }

  void startWeatherPolling() async {
    var weatherStream = weather.weatherStream;

    weatherStream.listen((weatherMessage) async {
      await telegram.sendMessage(chatId, weatherMessage);
    });
  }

  void startPanoramaNewsPolling() async {
    await setupPanoramaNews();

    Timer.periodic(Duration(hours: 5, minutes: 41), (_) async {
      var hour = DateTime.now().hour;

      if (hour <= 9 || hour >= 23) return;

      await _sendNewsToChat(null);
    });
  }

  void startJokesPolling() async {
    Timer.periodic(Duration(hours: 2, minutes: 13), (_) async {
      var hour = DateTime.now().hour;

      if (hour <= 9 || hour >= 23) return;

      await _sendJokeToChat(null);
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
    bot.onCommand('increp').listen((TeleDartMessage message) => _updateReputation(message, 'increase'));
    bot.onCommand('decrep').listen((TeleDartMessage message) => _updateReputation(message, 'decrease'));
    bot.onCommand('replist').listen(_sendReputationList);
    bot.onCommand('searchsong').listen(_searchYoutubeTrack);

    var bullyTagUserRegexp = RegExp(sm.get('bully_tag_user_regexp'), caseSensitive: false);
    bot.onMessage(keyword: bullyTagUserRegexp).listen(_bullyTagUser);

    var bullyWeatherMessageRegexp = RegExp(sm.get('bully_weather_regexp'), caseSensitive: false);
    bot.onMessage(keyword: bullyWeatherMessageRegexp).listen(_getBullyWeatherForCity);

    bot.onInlineQuery().listen((query) {
      debouncer.value = query;
    });
    debouncer.values.listen((query) {
      _searchYoutubeTrackInline(query as TeleDartInlineQuery);
    });
  }

  void _addCity(TeleDartMessage message) async {
    var cityToAdd = _getOneParameterFromMessage(message);

    if (cityToAdd.isEmpty) {
      await message.reply('Provide one city to add!');
      return;
    }

    var result = await weather.addCity(cityToAdd);

    if (result) {
      await message.reply('City $cityToAdd has been added to the watchlist!');
    } else {
      await message.reply('Error');
    }
  }

  void _removeCity(TeleDartMessage message) async {
    var cityToRemove = _getOneParameterFromMessage(message);

    if (cityToRemove.isEmpty) {
      await message.reply('Provide one city to remove!');
      return;
    }

    var result = await weather.removeCity(cityToRemove);

    if (result) {
      await message.reply('City $cityToRemove has been removed from the watchlist!');
    } else {
      await message.reply('Error');
    }
  }

  void _getWatchlist(TeleDartMessage message) async {
    var citiesString = await weather.getWatchList();

    await message.reply("I'm watching these cities:\n$citiesString");
  }

  void _getWeatherForCity(TeleDartMessage message) async {
    var city = _getOneParameterFromMessage(message);

    if (city.isEmpty) {
      await message.reply('Provide a city!');
      return;
    }

    var temperature = await weather.getWeatherForCity(city);

    if (temperature != null) {
      await message.reply('In city $city the temperature is $temperature°C');
    } else {
      await message.reply('There was an error processing your request! Try again');
    }
  }

  void _ping(TeleDartMessage message) async {
    // various things to test are here
  }

  void _setNotificationHour(TeleDartMessage message) async {
    var nextHour = _getOneParameterFromMessage(message);

    if (nextHour.isEmpty) {
      await message.reply('Incorrect value for notification hour. Please use single number from 0 to 23');
      return;
    }

    var result = weather.setNotificationsHour(int.parse(nextHour));

    if (result) {
      await message.reply('Notification hour has been set to $nextHour');
    } else {
      await message.reply('Error');
    }
  }

  void _getBullyWeatherForCity(TeleDartMessage message) async {
    var messageWords = message.text?.split(RegExp(r'(,)|(\s{1,})')).where((item) => item.isNotEmpty).toList();

    if (messageWords == null || messageWords.length != 3 || (messageWords[0] != sm.get('yo') && messageWords[1] != sm.get('dude'))) {
      return;
    }

    var city = messageWords[2];

    try {
      var temperature = await weather.getWeatherForCity(city);

      if (temperature == null) {
        throw 'No temperature';
      }

      await message.reply(sm.get('weather_in_city', {'city': city, 'temp': temperature.toString()}));
    } catch (err) {
      print(err);

      await message.reply(sm.get('error_occurred'));
    }
  }

  void _bullyTagUser(TeleDartMessage message) async {
    var denisId = 354903232;

    if (message.from?.id == adminId) {
      await message.reply('@daimonil');
    } else if (message.from?.id == denisId) {
      await message.reply('@dmbaranov_io');
    }
  }

  void _writeToCoop(TeleDartMessage message) async {
    if (message.text == null) {
      await message.reply(sm.get('do_not_do_this'));
      return;
    }

    var rawText = message.text?.split(' ');
    var text = rawText?.sublist(1).join(' ') ?? '';

    print('${message.from?.toJson()} is writing to Coop: ${message.toJson()}');

    try {
      await telegram.sendMessage(chatId, text);
    } catch (e) {
      await message.reply(sm.get('do_not_do_this'));
    }
  }

  String _getOneParameterFromMessage(TeleDartMessage message) {
    var options = message.text?.split(' ');

    if (options == null || options.length != 2) return '';

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

    var updateMessage = sm.get('update_completed', {'update': commitMessage});

    await telegram.sendMessage(chatId, updateMessage);
  }

  Future<void> _sendNewsToChat(TeleDartMessage? message) async {
    var instantViewUrl = 'a.devs.today/';
    var news = await getNews();

    if (news.title.isEmpty) return;

    var message = '${news.title}\n\nFull<a href="${instantViewUrl + news.url}">:</a> ${news.url}';

    await telegram.sendMessage(chatId, message, parse_mode: 'HTML');
  }

  Future<void> _sendJokeToChat(TeleDartMessage? message) async {
    var joke = await dadJokes.getJoke();

    await telegram.sendMessage(chatId, joke.joke);
  }

  Future<void> _sendRealMusic(TeleDartMessage message) async {
    if (message.text == null || message.text?.contains('music.youtube.com') == false) {
      await message.reply(sm.get('do_not_do_this'));
      return;
    }

    var rawText = message.text?.split(' ');

    if (rawText == null) {
      return;
    }

    var text = rawText.sublist(1).join(' ');
    text = text.replaceAll('music.', '');

    try {
      await telegram.sendMessage(chatId, text);
    } catch (e) {
      await message.reply(sm.get('do_not_do_this'));
    }
  }

  Future<void> _searchYoutubeTrack(TeleDartMessage message) async {
    var query = message.text?.split(' ').sublist(1).join(' ');

    if (query == null || query.isEmpty) {
      await message.reply(sm.get('do_not_do_this'));
      return;
    }

    var videoUrl = await youtube.getYoutubeVideoUrl(query);

    if (videoUrl.isEmpty) {
      await message.reply(sm.get('not_found'));
    } else {
      await message.reply(videoUrl);
    }
  }

  Future<void> _searchYoutubeTrackInline(TeleDartInlineQuery query) async {
    var searchResults = await youtube.getYoutubeSearchResults(query.query);
    List items = searchResults['items'];
    var inlineQueryResult = [];

    items.forEach((searchResult) {
      var videoId = searchResult['id']['videoId'];
      var videoData = searchResult['snippet'];
      var videoUrl = 'https://www.youtube.com/watch?v=$videoId';

      inlineQueryResult.add(InlineQueryResultVideo(
          id: videoId,
          title: videoData['title'],
          thumb_url: videoData['thumbnails']['high']['url'],
          mime_type: 'video/mp4',
          video_duration: 600,
          video_url: videoUrl,
          input_message_content: InputTextMessageContent(message_text: videoUrl, disable_web_page_preview: false)));
    });

    await bot.answerInlineQuery(query.id, [...inlineQueryResult], cache_time: 10);
  }

  Future<void> _updateReputation(TeleDartMessage message, String change) async {
    if (message.reply_to_message == null) {
      await message.reply(sm.get('error_occurred'));
      return;
    }

    var fromId = message.from?.id.toString();
    var toId = message.reply_to_message?.from?.id.toString();

    var changeResult = await reputation.updateReputation(fromId, toId, change);

    await message.reply(changeResult);
  }

  Future<void> _sendReputationList(TeleDartMessage message) async {
    var reputationMessage = reputation.getReputationMessage();

    await message.reply(reputationMessage);
  }
}
