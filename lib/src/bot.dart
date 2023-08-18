import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:postgres/postgres.dart';
import 'package:http/http.dart' as http;

import 'package:weather/src/platform/platform.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/command.dart';
import 'package:weather/src/globals/message_event.dart';

import 'package:weather/src/modules/chat_manager.dart';
import 'package:weather/src/modules/database-manager/database_manager.dart';
import 'package:weather/src/modules/user_manager.dart';
import 'package:weather/src/modules/weather_manager.dart';
import 'package:weather/src/modules/panorama.dart';
import 'package:weather/src/modules/dadjokes.dart';
import 'package:weather/src/modules/reputation.dart';
import 'package:weather/src/modules/youtube.dart';
import 'package:weather/src/modules/conversator.dart';
import 'package:weather/src/modules/commands_manager.dart';

class Bot {
  final ChatPlatform platformName;
  final String botToken;
  final String adminId;
  final String repoUrl;
  final String openweatherKey;
  final String youtubeKey;
  final String conversatorKey;
  final PostgreSQLConnection dbConnection;

  late Platform _platform;
  late DatabaseManager _dbManager;
  late UserManager _userManager;
  late WeatherManager _weatherManager;
  late DadJokes _dadJokes;
  late PanoramaNews _panoramaNews;
  late Reputation _reputation;
  late Youtube _youtube;
  late Conversator _conversator;
  late ChatManager _chatManager;
  late CommandsManager _cm;

  Bot(
      {required this.platformName,
      required this.botToken,
      required this.adminId,
      required this.repoUrl,
      required this.openweatherKey,
      required this.youtubeKey,
      required this.conversatorKey,
      required this.dbConnection});

  Future<void> startBot() async {
    _dbManager = DatabaseManager(dbConnection);
    await _dbManager.initialize();

    _dadJokes = DadJokes();
    _youtube = Youtube(youtubeKey);
    _conversator = Conversator(dbManager: _dbManager, conversatorApiKey: conversatorKey);
    _cm = CommandsManager(adminId: adminId, dbManager: _dbManager);

    _chatManager = ChatManager(dbManager: _dbManager);
    await _chatManager.initialize();

    _panoramaNews = PanoramaNews(dbManager: _dbManager);
    _panoramaNews.initialize();

    _userManager = UserManager(dbManager: _dbManager);
    _userManager.initialize();

    _reputation = Reputation(dbManager: _dbManager);
    _reputation.initialize();

    _weatherManager = WeatherManager(dbManager: _dbManager, openweatherKey: openweatherKey);
    await _weatherManager.initialize();

    _platform = Platform(
        chatPlatform: platformName,
        token: botToken,
        adminId: adminId,
        chatManager: _chatManager,
        youtube: _youtube,
        userManager: _userManager);
    await _platform.initializePlatform();
    _platform.setupPlatformSpecificCommands(_cm);

    _setupCommands();
    _subscribeToUserUpdates();
    _subscribeToWeatherUpdates();
    _subscribeToPanoramaNews();

    await _platform.postStart();
  }

  void _setupCommands() {
    _platform.setupCommand(Command(
        command: 'addcity',
        description: '[U] Add city to the watchlist',
        wrapper: _cm.userCommand,
        withParameters: true,
        successCallback: _addWeatherCity));

    _platform.setupCommand(Command(
        command: 'removecity',
        description: '[U] Remove city from the watchlist',
        wrapper: _cm.userCommand,
        withParameters: true,
        successCallback: _removeWeatherCity));

    _platform.setupCommand(Command(
        command: 'watchlist', description: '[U] Get weather watchlist', wrapper: _cm.userCommand, successCallback: _getWeatherWatchlist));

    _platform.setupCommand(Command(
        command: 'getweather',
        description: '[U] Get weather for city',
        wrapper: _cm.userCommand,
        withParameters: true,
        successCallback: _getWeatherForCity));

    _platform.setupCommand(Command(
        command: 'setnotificationhour',
        description: '[M] Set time for weather notifications',
        wrapper: _cm.moderatorCommand,
        withParameters: true,
        successCallback: _setWeatherNotificationHour));

    _platform.setupCommand(Command(
        command: 'write',
        description: '[M] Write message to the chat on behalf of the bot',
        wrapper: _cm.moderatorCommand,
        withParameters: true,
        successCallback: _writeToChat));

    _platform.setupCommand(Command(
        command: 'updatemessage', description: '[A] Post update message', wrapper: _cm.adminCommand, successCallback: _postUpdateMessage));

    _platform.setupCommand(
        Command(command: 'sendnews', description: '[U] Send news to the chat', wrapper: _cm.userCommand, successCallback: _sendNewsToChat));

    _platform.setupCommand(
        Command(command: 'sendjoke', description: '[U] Send joke to the chat', wrapper: _cm.userCommand, successCallback: _sendJokeToChat));

    _platform.setupCommand(Command(
        command: 'sendrealmusic',
        description: '[U] Convert link from YouTube Music to YouTube',
        wrapper: _cm.userCommand,
        withParameters: true,
        successCallback: _sendRealMusicToChat));

    _platform.setupCommand(Command(
        command: 'increp',
        description: '[U] Increase reputation for the user',
        wrapper: _cm.userCommand,
        withOtherUserIds: true,
        successCallback: _increaseReputation));

    _platform.setupCommand(Command(
        command: 'decrep',
        description: '[U] Decrease reputation for the user',
        wrapper: _cm.userCommand,
        withOtherUserIds: true,
        successCallback: _decreaseReputation));

    _platform.setupCommand(Command(
        command: 'replist',
        description: '[U] Send reputation list to the chat',
        wrapper: _cm.userCommand,
        successCallback: _sendReputationList));

    _platform.setupCommand(Command(
        command: 'searchsong',
        description: '[U] Search song on YouTube',
        wrapper: _cm.userCommand,
        withParameters: true,
        successCallback: _searchYoutubeTrack));

    _platform.setupCommand(Command(
        command: 'ask',
        description: '[U] Ask for advice or anything else from the Conversator',
        wrapper: _cm.userCommand,
        conversatorCommand: true,
        successCallback: _askConversator));

    _platform.setupCommand(
        Command(command: 'na', description: '[U] Check if bot is alive', wrapper: _cm.userCommand, successCallback: _healthCheck));

    _platform.setupCommand(Command(
        command: 'initialize', description: '[A] Initialize new chat', wrapper: _cm.adminCommand, successCallback: _initializeChat));

    _platform.setupCommand(Command(
        command: 'adduser',
        description: '[M] Add new user to the bot',
        wrapper: _cm.moderatorCommand,
        withOtherUserIds: true,
        successCallback: _addUser));

    _platform.setupCommand(Command(
        command: 'removeuser',
        description: '[M] Remove user from the bot',
        wrapper: _cm.moderatorCommand,
        withOtherUserIds: true,
        successCallback: _removeUser));

    _platform.setupCommand(Command(
        command: 'createreputation',
        description: '[A] Create reputation for the user',
        wrapper: _cm.adminCommand,
        withOtherUserIds: true,
        successCallback: _createReputation));

    _platform.setupCommand(Command(
        command: 'createweather',
        description: '[A] Activate weather module for the chat',
        wrapper: _cm.adminCommand,
        successCallback: _createWeather));

    _platform.setupCommand(Command(
        command: 'setswearwordsconfig',
        description: '[A] Set swearwords config for the chat',
        wrapper: _cm.adminCommand,
        withParameters: true,
        successCallback: _setSwearwordsConfig));
  }

  void _subscribeToUserUpdates() {
    _userManager.userManagerStream.listen((_) async {
      await _updateUsersPremiumStatus();
    });
  }

  void _subscribeToWeatherUpdates() {
    var weatherStream = _weatherManager.weatherStream;

    weatherStream.listen((weatherData) {
      var message = '';

      weatherData.weatherData.forEach((weatherData) {
        message += 'In city: ${weatherData.city} the temperature is ${weatherData.temp}\n\n';
      });

      _platform.sendMessage(weatherData.chatId, message);
    });
  }

  // TODO: add news_enabled flag and send news to all the enabled chats
  void _subscribeToPanoramaNews() {
    var panoramaStream = _panoramaNews.panoramaStream;

    panoramaStream.listen((event) async {
      var allChats = await _chatManager.getAllChatIdsForPlatform(ChatPlatform.telegram);

      allChats.forEach((chatId) {
        var fakeEvent = MessageEvent(
            platform: ChatPlatform.telegram, chatId: chatId, userId: '', isBot: false, otherUserIds: [], parameters: [], rawMessage: '');

        _sendNewsToChat(fakeEvent);
      });
    });
  }

  Future<void> _updateUsersPremiumStatus() async {
    var allPlatformChatIds = await _chatManager.getAllChatIdsForPlatform(platformName);

    await Future.forEach(allPlatformChatIds, (chatId) async {
      var chatUsers = await _userManager.getUsersForChat(chatId);

      await Future.forEach(chatUsers, (chatUser) async {
        await Future.delayed(Duration(seconds: 1));

        var platformUserPremiumStatus = await _platform.getUserPremiumStatus(chatId, chatUser.id);

        if (chatUser.isPremium != platformUserPremiumStatus) {
          print('Updating premium status for ${chatUser.id}');
          await _userManager.updatePremiumStatus(chatUser.id, platformUserPremiumStatus);
        }
      });
    });
  }

  bool _parametersCheck(MessageEvent event, [int numberOfParameters = 1]) {
    if (event.parameters.whereNot((parameter) => parameter.isEmpty).length < numberOfParameters) {
      _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'general.something_went_wrong'));

      return false;
    }

    return true;
  }

  bool _userIdsCheck(MessageEvent event, [int numberOfIds = 1]) {
    if (event.otherUserIds.whereNot((id) => id.isEmpty).length < numberOfIds) {
      _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'general.something_went_wrong'));

      return false;
    }

    return true;
  }

  void _sendOperationMessage(String chatId, bool operationResult, String successfulMessage) {
    if (operationResult) {
      _platform.sendMessage(chatId, successfulMessage);
    } else {
      _platform.sendMessage(chatId, _chatManager.getText(chatId, 'general.something_went_wrong'));
    }
  }

  void _handleReputationChange(MessageEvent event, ReputationChangeResult result) async {
    switch (result) {
      case ReputationChangeResult.increaseSuccess:
        await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'reputation.change.increase_success'));
        break;
      case ReputationChangeResult.decreaseSuccess:
        await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'reputation.change.decrease_success'));
        break;
      case ReputationChangeResult.userNotFound:
        await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'reputation.change.user_not_found'));
        break;
      case ReputationChangeResult.selfUpdate:
        await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'reputation.change.self_update'));
        break;
      case ReputationChangeResult.notEnoughOptions:
        await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'reputation.change.not_enough_options'));
        break;
      case ReputationChangeResult.systemError:
        await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'general.something_went_wrong'));
        break;
    }
  }

  void _addWeatherCity(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var cityToAdd = event.parameters[0];
    var result = await _weatherManager.addCity(event.chatId, event.parameters[0]);

    _sendOperationMessage(event.chatId, result, _chatManager.getText(event.chatId, 'weather.cities.added', {'city': cityToAdd}));
  }

  void _removeWeatherCity(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var cityToRemove = event.parameters[0];
    var result = await _weatherManager.removeCity(event.chatId, event.parameters[0]);

    _sendOperationMessage(event.chatId, result, _chatManager.getText(event.chatId, 'weather.cities.removed', {'city': cityToRemove}));
  }

  void _getWeatherWatchlist(MessageEvent event) async {
    var cities = await _weatherManager.getWatchList(event.chatId);
    var citiesString = cities.join('\n');

    await _platform.sendMessage(event.chatId, citiesString);
  }

  void _getWeatherForCity(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var city = event.parameters[0];
    var temperature = await _weatherManager.getWeatherForCity(city);

    _sendOperationMessage(event.chatId, temperature != null,
        _chatManager.getText(event.chatId, 'weather.cities.temperature', {'city': city, 'temperature': temperature.toString()}));
  }

  void _setWeatherNotificationHour(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var nextHour = event.parameters[0];
    var result = await _weatherManager.setNotificationHour(event.chatId, int.parse(nextHour));

    _sendOperationMessage(
        event.chatId, result, _chatManager.getText(event.chatId, 'weather.other.notification_hour_set', {'hour': nextHour}));
  }

  void _writeToChat(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    await _platform.sendMessage(event.chatId, event.parameters.join(' '));
  }

  void _postUpdateMessage(MessageEvent event) async {
    var commitApiUrl = Uri.https('api.github.com', '/repos$repoUrl/commits');
    var response = await http.read(commitApiUrl).then(json.decode);
    var updateMessage = response[0]['commit']['message'];
    var chatIds = await _chatManager.getAllChatIdsForPlatform(event.platform);

    chatIds.forEach((chatId) => _platform.sendMessage(chatId, updateMessage));
  }

  void _sendNewsToChat(MessageEvent event) async {
    var news = await _panoramaNews.getNews(event.chatId);

    if (news != null) {
      var newsMessage = '${news.title}\n\nFull: ${news.url}';

      await _platform.sendMessage(event.chatId, newsMessage);
    } else {
      await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'general.something_went_wrong'));
    }
  }

  void _sendJokeToChat(MessageEvent event) async {
    var joke = await _dadJokes.getJoke();

    await _platform.sendMessage(event.chatId, joke.joke);
  }

  void _sendRealMusicToChat(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var formattedLink = event.parameters[0].replaceAll('music.', '');

    await _platform.sendMessage(event.chatId, formattedLink);
  }

  void _increaseReputation(MessageEvent event) async {
    if (!_userIdsCheck(event)) return;

    var fromUserId = event.userId;
    var toUserId = event.otherUserIds[0];

    var result = await _reputation.updateReputation(
        chatId: event.chatId, fromUserId: fromUserId, toUserId: toUserId, change: ReputationChangeOption.increase);

    _handleReputationChange(event, result);
  }

  void _decreaseReputation(MessageEvent event) async {
    if (!_userIdsCheck(event)) return;

    var fromUserId = event.userId;
    var toUserId = event.otherUserIds[0];

    var result = await _reputation.updateReputation(
        chatId: event.chatId, fromUserId: fromUserId, toUserId: toUserId, change: ReputationChangeOption.decrease);

    _handleReputationChange(event, result);
  }

  void _sendReputationList(MessageEvent event) async {
    var reputationData = await _reputation.getReputationData(event.chatId);
    var reputationMessage = '';

    reputationData.forEach((reputation) {
      reputationMessage += _chatManager
          .getText(event.chatId, 'reputation.other.line', {'name': reputation.name, 'reputation': reputation.reputation.toString()});
    });

    _sendOperationMessage(event.chatId, reputationMessage.isNotEmpty,
        _chatManager.getText(event.chatId, 'reputation.other.list', {'reputation': reputationMessage}));
  }

  void _searchYoutubeTrack(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var videoUrl = await _youtube.getYoutubeVideoUrl(event.parameters.join(' '));

    _sendOperationMessage(event.chatId, videoUrl.isNotEmpty, videoUrl);
  }

  void _askConversator(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var parentMessageId = event.parameters[0];
    var currentMessageId = event.parameters[1];
    var message = event.parameters[2];

    var response = await _conversator.getConversationReply(
        chatId: event.chatId, parentMessageId: parentMessageId, currentMessageId: currentMessageId, message: message);

    var conversatorResponseMessage = await _platform.sendMessage(event.chatId, response);
    var conversatorResponseMessageId = _platform.getMessageId(conversatorResponseMessage);
    var conversationId = await _conversator.getConversationId(event.chatId, parentMessageId);

    await _conversator.saveConversationMessage(
        chatId: event.chatId,
        conversationId: conversationId,
        currentMessageId: conversatorResponseMessageId,
        message: response,
        fromUser: false);
  }

  void _healthCheck(MessageEvent event) async {
    await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'general.bot_is_alive'));
  }

  void _initializeChat(MessageEvent event) async {
    var chatName = 'Unknown';

    if (event.platform == ChatPlatform.telegram) {
      chatName = event.rawMessage.chat.title.toString();
    } else if (event.platform == ChatPlatform.discord) {
      chatName = event.rawMessage.guild.name.toString();
    }

    var result = await _chatManager.createChat(id: event.chatId, name: chatName, platform: event.platform);

    _sendOperationMessage(event.chatId, result, _chatManager.getText(event.chatId, 'chat.initialization.success'));
  }

  void _addUser(MessageEvent event) async {
    if (!_userIdsCheck(event) && !_parametersCheck(event)) return;

    var username = event.parameters[0];
    var isPremium = event.parameters[1] == 'true';

    var addResult = await _userManager.addUser(userId: event.otherUserIds[0], chatId: event.chatId, name: username, isPremium: isPremium);

    _sendOperationMessage(event.chatId, addResult, _chatManager.getText(event.chatId, 'user.user_added'));
  }

  void _removeUser(MessageEvent event) async {
    if (!_userIdsCheck(event)) return;

    var removeResult = await _userManager.removeUser(event.chatId, event.otherUserIds[0]);

    _sendOperationMessage(event.chatId, removeResult, _chatManager.getText(event.chatId, 'user.user_removed'));
  }

  void _createReputation(MessageEvent event) async {
    if (!_userIdsCheck(event)) return;

    var result = await _reputation.createReputationData(event.chatId, event.otherUserIds[0]);

    _sendOperationMessage(event.chatId, result, _chatManager.getText(event.chatId, 'general.success'));
  }

  void _createWeather(MessageEvent event) async {
    var result = await _weatherManager.createWeatherData(event.chatId);

    _sendOperationMessage(event.chatId, result, _chatManager.getText(event.chatId, 'general.success'));
  }

  void _setSwearwordsConfig(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var result = await _chatManager.setSwearwordsConfig(event.chatId, event.parameters[0]);

    _sendOperationMessage(event.chatId, result, _chatManager.getText(event.chatId, 'general.success'));
  }
}
