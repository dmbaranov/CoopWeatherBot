import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:cron/cron.dart';

import 'package:weather/src/modules/swearwords_manager.dart';
import 'package:weather/src/modules/user_manager.dart';
import 'package:weather/src/modules/weather.dart';
import 'package:weather/src/modules/panorama.dart';
import 'package:weather/src/modules/dadjokes.dart';
import 'package:weather/src/modules/reputation.dart';
import 'package:weather/src/modules/youtube.dart';
import 'package:weather/src/modules/accordion_poll.dart';

import './commands.dart';

class TelegramBot {
  final String token;
  final int chatId;
  final String repoUrl;
  final int adminId;
  final String youtubeKey;
  final String openweatherKey;
  late TeleDart bot;
  late Telegram telegram;
  late SwearwordsManager sm;
  late UserManager userManager;
  late Weather weather;
  late DadJokes dadJokes;
  late PanoramaNews panoramaNews;
  late Reputation reputation;
  late Youtube youtube;
  late AccordionPoll accordionPoll;
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
    dadJokes = DadJokes();
    panoramaNews = PanoramaNews();
    youtube = Youtube(youtubeKey);

    bot.start();

    sm = SwearwordsManager();
    await sm.initialize();

    userManager = UserManager();
    await userManager.initialize();

    reputation = Reputation(sm: sm);
    await reputation.initialize();

    weather = Weather(openweatherKey: openweatherKey);
    weather.initialize();

    await panoramaNews.initialize();

    accordionPoll = AccordionPoll(sm: sm);

    _setupListeners();

    _subscribeToWeather();
    _startPanoramaNewsJob();
    _startJokesJob();

    print('Bot has been started!');
  }

  void _subscribeToWeather() {
    var weatherStream = weather.weatherStream;

    weatherStream.listen((weatherMessage) {
      telegram.sendMessage(chatId, weatherMessage);
    });
  }

  void _startPanoramaNewsJob() async {
    Cron().schedule(Schedule.parse('0 10,15,20 * * *'), () async {
      await sendNewsToChat(this);
    });
  }

  void _startJokesJob() async {
    Cron().schedule(Schedule.parse('30 11,17,21 * * *'), () async {
      await sendJokeToChat(this);
    });
  }

  void _setupListeners() {
    bot.onCommand('addcity').listen((event) => addCity(this, event));
    bot.onCommand('removecity').listen((event) => removeCity(this, event));
    bot.onCommand('watchlist').listen((event) => getWatchlist(this, event));
    bot.onCommand('getweather').listen((event) => getWeatherForCity(this, event));
    bot.onCommand('setnotificationhour').listen((event) => setNotificationHour(this, event));
    bot.onCommand('write').listen((event) => writeToCoop(this, event));
    bot.onCommand('updatemessage').listen((event) => postUpdateMessage(this));
    bot.onCommand('sendnews').listen((event) => sendNewsToChat(this));
    bot.onCommand('sendjoke').listen((event) => sendJokeToChat(this));
    bot.onCommand('sendrealmusic').listen((event) => sendRealMusic(this, event));
    bot.onCommand('increp').listen((event) => updateReputation(this, event, 'increase'));
    bot.onCommand('decrep').listen((event) => updateReputation(this, event, 'decrease'));
    bot.onCommand('replist').listen((event) => sendReputationList(this, event));
    bot.onCommand('searchsong').listen((event) => searchYoutubeTrack(this, event));
    bot.onCommand('na').listen((event) => checkIfAlive(this, event));
    bot.onCommand('accordion').listen((event) => startAccordionPoll(this, event));
    bot.onCommand('adduser').listen((event) => addUser(this, event));
    bot.onCommand('removeuser').listen((event) => removeUser(this, event));

    var bullyTagUserRegexp = RegExp(sm.get('bully_tag_user_regexp'), caseSensitive: false);
    bot.onMessage(keyword: bullyTagUserRegexp).listen((event) => bullyTagUser(this, event));

    bot.onInlineQuery().listen((query) {
      debouncer.value = query;
    });
    debouncer.values.listen((query) {
      searchYoutubeTrackInline(this, query as TeleDartInlineQuery);
    });
  }
}
