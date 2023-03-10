import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:cron/cron.dart';
import 'package:postgres/postgres.dart';

import 'package:weather/src/modules/database-manager/database_manager.dart';
import 'package:weather/src/modules/swearwords_manager.dart';
import 'package:weather/src/modules/user_manager.dart';
import 'package:weather/src/modules/weather_manager.dart';
import 'package:weather/src/modules/panorama.dart';
import 'package:weather/src/modules/dadjokes.dart';
import 'package:weather/src/modules/reputation.dart';
import 'package:weather/src/modules/youtube.dart';
import 'package:weather/src/modules/accordion_poll.dart';
import 'package:weather/src/modules/conversator.dart';
import 'package:weather/src/modules/chat_manager.dart';

import './commands.dart';

class TelegramBot {
  final String token;
  final int chatId;
  final String repoUrl;
  final int adminId;
  final String youtubeKey;
  final String openweatherKey;
  final String conversatorKey;
  final PostgreSQLConnection dbConnection;
  late TeleDart bot;
  late Telegram telegram;
  late DatabaseManager dbManager;
  late SwearwordsManager sm;
  late UserManager userManager;
  late WeatherManager weatherManager;
  late DadJokes dadJokes;
  late PanoramaNews panoramaNews;
  late Reputation reputation;
  late Youtube youtube;
  late AccordionPoll accordionPoll;
  late Conversator conversator;
  late ChatManager chatManager;
  late int notificationHour = 7;
  late Debouncer<TeleDartInlineQuery?> debouncer = Debouncer(Duration(seconds: 1), initialValue: null);

  TelegramBot(
      {required this.token,
      required this.chatId,
      required this.repoUrl,
      required this.adminId,
      required this.youtubeKey,
      required this.openweatherKey,
      required this.conversatorKey,
      required this.dbConnection});

  void startBot() async {
    final botName = (await Telegram(token).getMe()).username;

    telegram = Telegram(token);
    bot = TeleDart(token, Event(botName!), fetcher: LongPolling(Telegram(token), limit: 100, timeout: 50));

    dbManager = DatabaseManager(dbConnection);
    await dbManager.initialize();

    dadJokes = DadJokes();
    panoramaNews = PanoramaNews();
    youtube = Youtube(youtubeKey);
    conversator = Conversator(conversatorKey);
    chatManager = ChatManager(dbManager: dbManager);

    bot.start();

    sm = SwearwordsManager();
    await sm.initialize();

    userManager = UserManager(dbManager: dbManager);
    await userManager.initialize();

    reputation = Reputation(sm: sm, userManager: userManager);
    await reputation.initialize();

    weatherManager = WeatherManager(openweatherKey: openweatherKey);
    weatherManager.initialize();

    await panoramaNews.initialize();

    accordionPoll = AccordionPoll(sm: sm);

    _setupListeners();

    _subscribeToWeather();
    _subscribeToUsersUpdate();
    _startPanoramaNewsJob();
    _startJokesJob();

    print('Bot has been started!');
  }

  void _subscribeToWeather() {
    var weatherStream = weatherManager.weatherStream;

    weatherStream.listen((weatherMessage) {
      telegram.sendMessage(chatId, weatherMessage);
    });
  }

  void _subscribeToUsersUpdate() {
    var userManagerStream = userManager.userManagerStream;

    userManagerStream.listen((_) {
      print('TODO: update users premium status');
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
    bot.onCommand('ask').listen((event) => getConversatorReply(this, event));
    bot.onCommand('adduser').listen((event) => addUser(this, event));
    bot.onCommand('removeuser').listen((event) => removeUser(this, event));
    bot.onCommand('initialize').listen((event) => initChat(this, event));

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
