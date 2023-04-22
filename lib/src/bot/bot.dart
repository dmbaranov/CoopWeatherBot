import 'dart:convert';
import 'package:collection/collection.dart';
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

// TODO: move part of the logic to utils using self
abstract class Bot<PlatformEvent, PlatformMessage> {
  final String botToken;
  final String adminId;
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
      required this.adminId,
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
    conversator = Conversator(dbManager: dbManager, conversatorApiKey: conversatorKey);
    chatManager = ChatManager(dbManager: dbManager);
    accordionPoll = AccordionPoll();
    cm = CommandsManager(adminId: adminId, dbManager: dbManager);

    sm = SwearwordsManager();
    await sm.initialize();

    panoramaNews = PanoramaNews(dbManager: dbManager);
    panoramaNews.initialize();

    userManager = UserManager(dbManager: dbManager);
    userManager.initialize();

    reputation = Reputation(dbManager: dbManager);
    reputation.initialize();

    weatherManager = WeatherManager(dbManager: dbManager, openweatherKey: openweatherKey);
    await weatherManager.initialize();
  }

  @protected
  void setupCommand(Command<PlatformEvent> command);

  @protected
  MessageEvent mapToGeneralMessageEvent(PlatformEvent event);

  @protected
  MessageEvent mapToMessageEventWithParameters(PlatformEvent event, [List? otherParameters]);

  @protected
  MessageEvent mapToMessageEventWithOtherUserIds(PlatformEvent event, [List? otherUserIds]);

  @protected
  MessageEvent mapToConversatorMessageEvent(PlatformEvent event);

  @protected
  Future<PlatformMessage> sendMessage(String chatId, String message);

  @protected
  String getMessageId(PlatformMessage message);

  @protected
  void setupPlatformSpecificCommands();

  void setupCommands() {
    setupCommand(Command(
        command: 'addcity',
        description: '[U] Add city to the watchlist',
        wrapper: cm.userCommand,
        withParameters: true,
        successCallback: addWeatherCity));

    setupCommand(Command(
        command: 'removecity',
        description: '[U] Remove city from the watchlist',
        wrapper: cm.userCommand,
        withParameters: true,
        successCallback: removeWeatherCity));

    setupCommand(Command(
        command: 'watchlist', description: '[U] Get weather watchlist', wrapper: cm.userCommand, successCallback: getWeatherWatchlist));

    setupCommand(Command(
        command: 'getweather',
        description: '[U] Get weather for city',
        wrapper: cm.userCommand,
        withParameters: true,
        successCallback: getWeatherForCity));

    setupCommand(Command(
        command: 'setnotificationhour',
        description: '[M] Set time for weather notifications',
        wrapper: cm.moderatorCommand,
        withParameters: true,
        successCallback: setWeatherNotificationHour));

    setupCommand(Command(
        command: 'write',
        description: '[M] Write message to the chat on behalf of the bot',
        wrapper: cm.moderatorCommand,
        withParameters: true,
        successCallback: writeToChat));

    setupCommand(Command(
        command: 'updatemessage', description: '[A] Post update message', wrapper: cm.adminCommand, successCallback: postUpdateMessage));

    setupCommand(
        Command(command: 'sendnews', description: '[U] Send news to the chat', wrapper: cm.userCommand, successCallback: sendNewsToChat));

    setupCommand(
        Command(command: 'sendjoke', description: '[U] Send joke to the chat', wrapper: cm.userCommand, successCallback: sendJokeToChat));

    setupCommand(Command(
        command: 'sendrealmusic',
        description: '[U] Convert link from YouTube Music to YouTube',
        wrapper: cm.userCommand,
        withParameters: true,
        successCallback: sendRealMusicToChat));

    setupCommand(Command(
        command: 'increp',
        description: '[U] Increase reputation for the user',
        wrapper: cm.userCommand,
        withOtherUserIds: true,
        successCallback: increaseReputation));

    setupCommand(Command(
        command: 'decrep',
        description: '[U] Decrease reputation for the user',
        wrapper: cm.userCommand,
        withOtherUserIds: true,
        successCallback: decreaseReputation));

    setupCommand(Command(
        command: 'replist',
        description: '[U] Send reputation list to the chat',
        wrapper: cm.userCommand,
        successCallback: sendReputationList));

    setupCommand(Command(
        command: 'searchsong',
        description: '[U] Search song on YouTube',
        wrapper: cm.userCommand,
        withParameters: true,
        successCallback: searchYoutubeTrack));

    setupCommand(Command(
        command: 'ask',
        description: '[U] Ask for advice or anything else from the Conversator',
        wrapper: cm.userCommand,
        conversatorCommand: true,
        successCallback: askConversator));

    setupCommand(Command(command: 'na', description: '[U] Check if bot is alive', wrapper: cm.userCommand, successCallback: healthCheck));

    setupCommand(
        Command(command: 'initialize', description: '[A] Initialize new chat', wrapper: cm.adminCommand, successCallback: initializeChat));

    setupCommand(Command(
        command: 'adduser',
        description: '[M] Add new user to the bot',
        wrapper: cm.moderatorCommand,
        withOtherUserIds: true,
        successCallback: addUser));

    setupCommand(Command(
        command: 'removeuser',
        description: '[M] Remove user from the bot',
        wrapper: cm.moderatorCommand,
        withOtherUserIds: true,
        successCallback: removeUser));

    setupCommand(Command(
        command: 'createreputation',
        description: '[A] Create reputation for the user',
        wrapper: cm.adminCommand,
        withOtherUserIds: true,
        successCallback: createReputation));

    setupCommand(Command(
        command: 'createweather',
        description: '[A] Activate weather module for the chat',
        wrapper: cm.adminCommand,
        successCallback: createWeather));
  }

  bool _parametersCheck(MessageEvent event, [int numberOfParameters = 1]) {
    if (event.parameters.whereNot((parameter) => parameter.isEmpty).length < numberOfParameters) {
      sendMessage(event.chatId, sm.get('general.something_went_wrong'));

      return false;
    }

    return true;
  }

  bool _userIdsCheck(MessageEvent event, [int numberOfIds = 1]) {
    if (event.otherUserIds.whereNot((id) => id.isEmpty).length < numberOfIds) {
      sendMessage(event.chatId, sm.get('general.something_went_wrong'));

      return false;
    }

    return true;
  }

  void _sendOperationMessage(String chatId, bool operationResult, String successfulMessage) {
    if (operationResult) {
      sendMessage(chatId, successfulMessage);
    } else {
      sendMessage(chatId, sm.get('general.something_went_wrong'));
    }
  }

  void _handleReputationChange(MessageEvent event, ReputationChangeResult result) async {
    switch (result) {
      case ReputationChangeResult.increaseSuccess:
        await sendMessage(event.chatId, sm.get('reputation.change.increase_success'));
        break;
      case ReputationChangeResult.decreaseSuccess:
        await sendMessage(event.chatId, sm.get('reputation.change.decrease_success'));
        break;
      case ReputationChangeResult.userNotFound:
        await sendMessage(event.chatId, sm.get('reputation.change.user_not_found'));
        break;
      case ReputationChangeResult.selfUpdate:
        await sendMessage(event.chatId, sm.get('reputation.change.self_update'));
        break;
      case ReputationChangeResult.notEnoughOptions:
        await sendMessage(event.chatId, sm.get('reputation.change.not_enough_options'));
        break;
      case ReputationChangeResult.systemError:
        await sendMessage(event.chatId, sm.get('general.something_went_wrong'));
        break;
    }
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

    _sendOperationMessage(event.chatId, result, sm.get('weather.cities.added', {'city': cityToAdd}));
  }

  @protected
  void removeWeatherCity(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var cityToRemove = event.parameters[0];
    var result = await weatherManager.removeCity(event.chatId, event.parameters[0]);

    _sendOperationMessage(event.chatId, result, sm.get('weather.cities.removed', {'city': cityToRemove}));
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

    _sendOperationMessage(
        event.chatId, temperature != null, sm.get('weather.cities.temperature', {'city': city, 'temperature': temperature.toString()}));
  }

  @protected
  void setWeatherNotificationHour(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var nextHour = event.parameters[0];
    var result = await weatherManager.setNotificationHour(event.chatId, int.parse(nextHour));

    _sendOperationMessage(event.chatId, result, sm.get('weather.other.notification_hour_set', {'hour': nextHour}));
  }

  @protected
  void writeToChat(MessageEvent event) async {
    await sendMessage(event.chatId, 'Currently not supported');
  }

  @protected
  void postUpdateMessage(MessageEvent event) async {
    // TODO: add support for Discord
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
  void sendRealMusicToChat(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var formattedLink = event.parameters[0].replaceAll('music.', '');

    await sendMessage(event.chatId, formattedLink);
  }

  @protected
  void increaseReputation(MessageEvent event) async {
    if (!_userIdsCheck(event)) return;

    var fromUserId = event.userId;
    var toUserId = event.otherUserIds[0];

    var result = await reputation.updateReputation(
        chatId: event.chatId, fromUserId: fromUserId, toUserId: toUserId, change: ReputationChangeOption.increase);

    _handleReputationChange(event, result);
  }

  @protected
  void decreaseReputation(MessageEvent event) async {
    if (!_userIdsCheck(event)) return;

    var fromUserId = event.userId;
    var toUserId = event.otherUserIds[0];

    var result = await reputation.updateReputation(
        chatId: event.chatId, fromUserId: fromUserId, toUserId: toUserId, change: ReputationChangeOption.decrease);

    _handleReputationChange(event, result);
  }

  @protected
  void sendReputationList(MessageEvent event) async {
    var reputationData = await reputation.getReputationMessage(event.chatId);
    var reputationMessage = '';

    reputationData.forEach((reputation) {
      reputationMessage += sm.get('reputation.other.line', {'name': reputation.name, 'reputation': reputation.reputation.toString()});
    });

    _sendOperationMessage(event.chatId, reputationMessage.isNotEmpty, sm.get('reputation.other.list', {'reputation': reputationMessage}));
  }

  @protected
  void searchYoutubeTrack(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var videoUrl = await youtube.getYoutubeVideoUrl(event.parameters.join(' '));

    _sendOperationMessage(event.chatId, videoUrl.isNotEmpty, videoUrl);
  }

  @protected
  void healthCheck(MessageEvent event) async {
    await sendMessage(event.chatId, sm.get('general.bot_is_alive'));
  }

  @protected
  void askConversator(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var parentMessageId = event.parameters[0];
    var currentMessageId = event.parameters[1];
    var message = event.parameters[2];

    var response = await conversator.getConversationReply(
        chatId: event.chatId, parentMessageId: parentMessageId, currentMessageId: currentMessageId, message: message);

    var conversatorResponseMessage = await sendMessage(event.chatId, response);
    var conversatorResponseMessageId = getMessageId(conversatorResponseMessage);
    var conversationId = await conversator.getConversationId(event.chatId, parentMessageId);

    await conversator.saveConversationMessage(
        chatId: event.chatId,
        conversationId: conversationId,
        currentMessageId: conversatorResponseMessageId,
        message: response,
        fromUser: false);
  }

  @protected
  void addUser(MessageEvent event) async {
    if (!_userIdsCheck(event)) return;

    var fullUsername = '';
    var isPremium = false;

    // TODO: move to utils
    if (event.platform == ChatPlatform.telegram) {
      var repliedUser = event.rawMessage.replyToMessage.from;

      fullUsername += repliedUser.firstName;

      if (repliedUser.username != null) {
        fullUsername += ' <${repliedUser.username}> ';
      }

      if (repliedUser.lastName != null) {
        fullUsername += repliedUser.lastName;
      }

      isPremium = repliedUser.isPremium ?? false;
    }

    var addResult =
        await userManager.addUser(userId: event.otherUserIds[0], chatId: event.chatId, name: fullUsername, isPremium: isPremium);

    _sendOperationMessage(event.chatId, addResult, sm.get('user.user_added'));
  }

  @protected
  void removeUser(MessageEvent event) async {
    if (!_userIdsCheck(event)) return;

    var removeResult = await userManager.removeUser(event.chatId, event.otherUserIds[0]);

    _sendOperationMessage(event.chatId, removeResult, sm.get('user.user_removed'));
  }

  @protected
  void initializeChat(MessageEvent event) async {
    var chatName = 'Unknown';

    if (event.platform == ChatPlatform.telegram) {
      chatName = event.rawMessage.chat.title.toString();
    }

    var result = await chatManager.createChat(id: event.chatId, name: chatName, platform: event.platform);

    _sendOperationMessage(event.chatId, result, sm.get('chat.initialization.success'));
  }

  @protected
  void createReputation(MessageEvent event) async {
    if (!_userIdsCheck(event)) return;

    var result = await reputation.createReputationData(event.chatId, event.otherUserIds[0]);

    _sendOperationMessage(event.chatId, result, sm.get('general.success'));
  }

  @protected
  void createWeather(MessageEvent event) async {
    var result = await weatherManager.createWeatherData(event.chatId);

    _sendOperationMessage(event.chatId, result, sm.get('general.success'));
  }
}
