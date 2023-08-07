import 'package:collection/collection.dart';
import 'package:postgres/postgres.dart';

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
    _platform.setupCommand(
        Command(command: 'na', description: '[U] Check if bot is alive', wrapper: _cm.userCommand, successCallback: _healthCheck));

    _platform.setupCommand(Command(
        command: 'ask',
        description: '[U] Ask for advice or anything else from the Conversator',
        wrapper: _cm.userCommand,
        conversatorCommand: true,
        successCallback: _askConversator));

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

  void _sendNewsToChat(MessageEvent event) async {
    var news = await _panoramaNews.getNews(event.chatId);

    if (news != null) {
      var newsMessage = '${news.title}\n\nFull: ${news.url}';

      await _platform.sendMessage(event.chatId, newsMessage);
    } else {
      await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'general.something_went_wrong'));
    }
  }

  void _healthCheck(MessageEvent event) async {
    await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'general.bot_is_alive'));
  }

  void _addWeatherCity(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var cityToRemove = event.parameters[0];
    var result = await _weatherManager.removeCity(event.chatId, event.parameters[0]);

    _sendOperationMessage(event.chatId, result, _chatManager.getText(event.chatId, 'weather.cities.removed', {'city': cityToRemove}));
  }

  void _removeWeatherCity(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var cityToRemove = event.parameters[0];
    var result = await _weatherManager.removeCity(event.chatId, event.parameters[0]);

    _sendOperationMessage(event.chatId, result, _chatManager.getText(event.chatId, 'weather.cities.removed', {'city': cityToRemove}));
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
}
