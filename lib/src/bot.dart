import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:postgres/postgres.dart';
import 'package:http/http.dart' as http;
import 'package:weather/src/core/database.dart';

import 'package:weather/src/platform/platform.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/message_event.dart';

import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/command.dart';
import 'package:weather/src/core/user.dart';

import 'package:weather/src/modules/chat/chat_manager.dart';
import 'package:weather/src/modules/user/user_manager.dart';
import 'package:weather/src/modules/weather/weather_manager.dart';
import 'package:weather/src/modules/panorama/panorama_manager.dart';
import 'package:weather/src/modules/dadjokes.dart';
import 'package:weather/src/modules/reputation/reputation_manager.dart';
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
  late Chat _chat;
  late Database _db;
  late Command _command;
  late User _user;

  late UserManager _userManager;

  late WeatherManager _weatherManager;
  late DadJokes _dadJokes;
  late PanoramaManager _panoramaManager;
  late ReputationManager _reputationManager;
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
    _db = Database(dbConnection);
    await _db.initialize();

    _chat = Chat(db: _db);
    _command = Command(adminId: adminId, db: _db);
    _user = User(db: _db);

    _dadJokes = DadJokes();
    _youtube = Youtube(youtubeKey);
    _conversator = Conversator(dbManager: _dbManager, conversatorApiKey: conversatorKey);
    _cm = CommandsManager(adminId: adminId, dbManager: _dbManager);

    _chatManager = ChatManager(platform: _platform, db: _db);
    await _chatManager.initialize();

    _panoramaManager = PanoramaManager(platform: _platform, chatManager: _chatManager, dbManager: _dbManager);
    _panoramaManager.initialize();

    _userManager = UserManager(dbManager: _dbManager);
    _userManager.initialize();

    _reputationManager = ReputationManager(platform: _platform, db: _db, chat: _chat);
    _reputationManager.initialize();

    _weatherManager = WeatherManager(platform: _platform, chat: _chat, db: _db, openweatherKey: openweatherKey);
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
    // TODO: check if these work
    // _subscribeToUserUpdates();
    // _subscribeToWeatherUpdates();
    // _subscribeToPanoramaNews();

    await _platform.postStart();
  }

  void _setupCommands() {
    _platform.setupCommand(Command(
        command: 'addcity',
        description: '[U] Add city to the watchlist',
        wrapper: _cm.userCommand,
        withParameters: true,
        successCallback: _weatherManager.addCity));

    _platform.setupCommand(Command(
        command: 'removecity',
        description: '[U] Remove city from the watchlist',
        wrapper: _cm.userCommand,
        withParameters: true,
        successCallback: _weatherManager.removeCity));

    _platform.setupCommand(Command(
        command: 'watchlist',
        description: '[U] Get weather watchlist',
        wrapper: _cm.userCommand,
        successCallback: _weatherManager.getWeatherWatchlist));

    _platform.setupCommand(Command(
        command: 'getweather',
        description: '[U] Get weather for city',
        wrapper: _cm.userCommand,
        withParameters: true,
        successCallback: _weatherManager.getWeatherForCity));

    _platform.setupCommand(Command(
        command: 'setnotificationhour',
        description: '[M] Set time for weather notifications',
        wrapper: _cm.moderatorCommand,
        withParameters: true,
        successCallback: _weatherManager.setWeatherNotificationHour));

    _platform.setupCommand(Command(
        command: 'write',
        description: '[M] Write message to the chat on behalf of the bot',
        wrapper: _cm.moderatorCommand,
        withParameters: true,
        successCallback: _writeToChat));

    _platform.setupCommand(Command(
        command: 'updatemessage', description: '[A] Post update message', wrapper: _cm.adminCommand, successCallback: _postUpdateMessage));

    _platform.setupCommand(Command(
        command: 'sendnews',
        description: '[U] Send news to the chat',
        wrapper: _cm.userCommand,
        successCallback: _panoramaManager.sendNewsToChat));

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
        successCallback: _reputationManager.increaseReputation));

    _platform.setupCommand(Command(
        command: 'decrep',
        description: '[U] Decrease reputation for the user',
        wrapper: _cm.userCommand,
        withOtherUserIds: true,
        successCallback: _reputationManager.decreaseReputation));

    _platform.setupCommand(Command(
        command: 'replist',
        description: '[U] Send reputation list to the chat',
        wrapper: _cm.userCommand,
        successCallback: _reputationManager.sendReputationList));

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
        command: 'initialize',
        description: '[A] Initialize new chat',
        wrapper: _cm.adminCommand,
        successCallback: _chatManager.createChat));

    _platform.setupCommand(Command(
        command: 'adduser',
        description: '[M] Add new user to the bot',
        wrapper: _cm.moderatorCommand,
        withOtherUserIds: true,
        successCallback: _userManager.addUser));

    _platform.setupCommand(Command(
        command: 'removeuser',
        description: '[M] Remove user from the bot',
        wrapper: _cm.moderatorCommand,
        withOtherUserIds: true,
        successCallback: _userManager.removeUser));

    _platform.setupCommand(Command(
        command: 'createreputation',
        description: '[A] Create reputation for the user',
        wrapper: _cm.adminCommand,
        withOtherUserIds: true,
        successCallback: _reputationManager.createReputation));

    _platform.setupCommand(Command(
        command: 'createweather',
        description: '[A] Activate weather module for the chat',
        wrapper: _cm.adminCommand,
        successCallback: _weatherManager.createWeather));

    _platform.setupCommand(Command(
        command: 'setswearwordsconfig',
        description: '[A] Set swearwords config for the chat',
        wrapper: _cm.adminCommand,
        withParameters: true,
        successCallback: _setSwearwordsConfig));
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

  void _sendJokeToChat(MessageEvent event) async {
    var joke = await _dadJokes.getJoke();

    await _platform.sendMessage(event.chatId, joke.joke);
  }

  void _sendRealMusicToChat(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var formattedLink = event.parameters[0].replaceAll('music.', '');

    await _platform.sendMessage(event.chatId, formattedLink);
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

  void _setSwearwordsConfig(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var result = await _chatManager.setSwearwordsConfig(event.chatId, event.parameters[0]);

    _sendOperationMessage(event.chatId, result, _chatManager.getText(event.chatId, 'general.success'));
  }
}
