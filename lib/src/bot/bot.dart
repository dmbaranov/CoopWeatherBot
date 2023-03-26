import 'package:meta/meta.dart';
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
import 'package:weather/src/modules/commands_manager.dart';

abstract class Bot {
  final String botToken;
  final String repoUrl;
  final String openweatherKey;
  final String youtubeKey;
  final String conversatorKey;
  final PostgreSQLConnection dbConnection;

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
  late CommandsManager cm;

  Bot(
      {required this.botToken,
      required this.repoUrl,
      required this.openweatherKey,
      required this.youtubeKey,
      required this.conversatorKey,
      required this.dbConnection});

  Future<void> startBot() async {
    dbManager = DatabaseManager(dbConnection);
    await dbManager.initialize();

    dadJokes = DadJokes();
    youtube = Youtube(youtubeKey);
    conversator = Conversator(conversatorKey);
    chatManager = ChatManager(dbManager: dbManager);
    panoramaNews = PanoramaNews(dbManager: dbManager);
    accordionPoll = AccordionPoll();
    cm = CommandsManager();

    sm = SwearwordsManager();
    await sm.initialize();

    userManager = UserManager(dbManager: dbManager);
    userManager.initialize();

    reputation = Reputation(dbManager: dbManager);
    reputation.initialize();

    weatherManager = WeatherManager(dbManager: dbManager, openweatherKey: openweatherKey);
    await weatherManager.initialize();
  }

  @protected
  setupCommands();

  @protected
  Future<void> sendMessage(String chatId, String message);

  @protected
  void subscribeToWeatherUpdates() {
    var weatherStream = weatherManager.weatherStream;

    weatherStream.listen((weatherData) {
      var message = '';

      weatherData.weatherData.forEach((weatherData) {
        message += 'In city: ${weatherData.city} the temperature is ${weatherData.temp}\n\n';
      });

      sendMessage(weatherData.chatId, message);
    });
  }

  @protected
  void subscribeToUsersUpdates() {
    var userManagerStream = userManager.userManagerStream;

    userManagerStream.listen((_) {
      print('TODO: update users premium status');
    });
  }

  @protected
  void addCity(MessageEvent event) {
    print('adding a city...');
  }

  @protected
  sendNoAccessMessage(MessageEvent event) {
    sendMessage(event.chatId, 'No access');
  }
}
