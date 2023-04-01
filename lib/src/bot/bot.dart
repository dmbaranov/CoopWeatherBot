import 'dart:convert';
import 'package:http/http.dart' as http;
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

// TODO: add stream for Panorama news
abstract class Bot {
  final String botToken;
  final String repoUrl;
  final String openweatherKey;
  final String youtubeKey;
  final String conversatorKey;
  final PostgreSQLConnection dbConnection;

  @protected
  late DatabaseManager dbManager;
  @protected
  late SwearwordsManager sm;
  @protected
  late UserManager userManager;
  @protected
  late WeatherManager weatherManager;
  @protected
  late DadJokes dadJokes;
  @protected
  late PanoramaNews panoramaNews;
  @protected
  late Reputation reputation;
  @protected
  late Youtube youtube;
  @protected
  late AccordionPoll accordionPoll;
  @protected
  late Conversator conversator;
  @protected
  late ChatManager chatManager;
  @protected
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

  bool _parametersCheck(MessageEvent event) {
    if (event.parameters.isEmpty) {
      sendMessage(event.chatId, sm.get('general.something_went_wrong'));

      return false;
    }

    return true;
  }

  bool _userIdsCheck(MessageEvent event) {
    if (event.otherUserIds.isEmpty) {
      sendMessage(event.chatId, sm.get('general.something_went_wrong'));

      return false;
    }

    return true;
  }

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
  sendNoAccessMessage(MessageEvent event) async {
    await sendMessage(event.chatId, sm.get('general.no_access'));
  }

  @protected
  sendErrorMessage(MessageEvent event) async {
    await sendMessage(event.chatId, sm.get('general.something_went_wrong'));
  }

  @protected
  void addWeatherCity(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var cityToAdd = event.parameters[0];
    var result = await weatherManager.addCity(event.chatId, cityToAdd);

    if (result) {
      await sendMessage(event.chatId, sm.get('weather.cities.added', {'city': cityToAdd}));
    } else {
      await sendMessage(event.chatId, sm.get('general.something_went_wrong'));
    }
  }

  @protected
  void removeWeatherCity(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var cityToRemove = event.parameters[0];
    var result = await weatherManager.removeCity(event.chatId, event.parameters[0]);

    if (result) {
      await sendMessage(event.chatId, sm.get('weather.cities.removed', {'city': cityToRemove}));
    } else {
      await sendMessage(event.chatId, sm.get('general.something_went_wrong'));
    }
  }

  @protected
  void getWeatherWatchlist(MessageEvent event) async {
    var cities = await weatherManager.getWatchList(event.chatId);
    var citiesString = cities.join('\n');

    await sendMessage(event.chatId, citiesString);
  }

  @protected
  void getWeatherForCity(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var city = event.parameters[0];
    var temperature = await weatherManager.getWeatherForCity(city);

    if (temperature != null) {
      await sendMessage(event.chatId, sm.get('weather.cities.temperature', {'city': city, 'temperature': temperature.toString()}));
    } else {
      await sendMessage(event.chatId, sm.get('general.something_went_wrong'));
    }
  }

  @protected
  void setWeatherNotificationHour(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var nextHour = event.parameters[0];
    var result = await weatherManager.setNotificationHour(event.chatId, int.parse(nextHour));

    if (result) {
      await sendMessage(event.chatId, sm.get('weather.other.notification_hour_set', {'hour': nextHour}));
    } else {
      await sendMessage(event.chatId, sm.get('general.something_went_wrong'));
    }
  }

  @protected
  void writeToChat(MessageEvent event) async {
    await sendMessage(event.chatId, 'Currently not supported');
  }

  @protected
  void postUpdateMessage(MessageEvent event) async {
    var commitApiUrl = Uri.https('api.github.com', '/repos$repoUrl/commits');
    var response = await http.read(commitApiUrl).then(json.decode);
    var updateMessage = response[0]['commit']['message'];
    var chatIds = await chatManager.getAllChatIds(ChatPlatform.telegram);

    chatIds.forEach((chatId) => sendMessage(chatId, updateMessage));
  }

  @protected
  void sendNewsToChat(MessageEvent event) async {
    var news = await panoramaNews.getNews(event.chatId);

    if (news != null) {
      var newsMessage = '${news.title}\n\nFull: ${news.url}';

      await sendMessage(event.chatId, newsMessage);
    } else {
      await sendMessage(event.chatId, sm.get('general.something_went_wrong'));
    }
  }

  @protected
  void sendJokeToChat(MessageEvent event) async {
    var joke = await dadJokes.getJoke();

    await sendMessage(event.chatId, joke.joke);
  }

  @protected
  void sendRealMusicToChat(MessageEvent event) {
    print('send real music to chat');
  }

  @protected
  void increaseReputation(MessageEvent event) {
    print('increasing reputation, ${event.userId}, ${event.otherUserIds[0]}');
  }

  @protected
  void decreaseReputation(MessageEvent event) {
    print('decreasing reputation');
  }

  @protected
  void sendReputationList(MessageEvent event) {
    print('sending a reputation list');
  }

  @protected
  void searchYoutubeTrack(MessageEvent event) {
    print('searching youtube track');
  }

  @protected
  void healthCheck(MessageEvent event) {
    print('check if bot is working');
  }

  @protected
  void startAccordionPoll(MessageEvent event) {
    print('start accordion poll');
  }

  @protected
  void askConversator(MessageEvent event) {
    print('asking a question');
  }

  @protected
  void addUser(MessageEvent event) {
    print('adding a user');
  }

  @protected
  void removeUser(MessageEvent event) {
    print('removing a user');
  }

  @protected
  void initializeChat(MessageEvent event) {
    print('initializing a chat');
  }

  @protected
  void createReputation(MessageEvent event) {
    print('creating a reputation');
  }

  @protected
  void createWeather(MessageEvent event) {
    print('creating a weather');
  }
}
