import 'package:postgres/postgres.dart';
import 'package:weather/src/core/database.dart';

import 'package:weather/src/platform/platform.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/bot_command.dart';

import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/command.dart';
import 'package:weather/src/core/user.dart';

import 'package:weather/src/modules/chat/chat_manager.dart';
import 'package:weather/src/modules/user/user_manager.dart';
import 'package:weather/src/modules/weather/weather_manager.dart';
import 'package:weather/src/modules/panorama/panorama_manager.dart';
import 'package:weather/src/modules/dadjokes/dadjokes_manager.dart';
import 'package:weather/src/modules/reputation/reputation_manager.dart';
import 'package:weather/src/modules/youtube/youtube_manager.dart';
import 'package:weather/src/modules/conversator/conversator_manager.dart';
import 'package:weather/src/modules/general/general_manager.dart';

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
  late DadJokesManager _dadJokesManager;
  late PanoramaManager _panoramaManager;
  late ReputationManager _reputationManager;
  late YoutubeManager _youtubeManager;
  late ConversatorManager _conversatorManager;
  late ChatManager _chatManager;
  late GeneralManager _generalManager;

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
    await _chat.initialize();

    _command = Command(adminId: adminId, db: _db);
    _user = User(db: _db)..initialize();

    _platform = Platform(chatPlatform: platformName, token: botToken, adminId: adminId, chat: _chat, user: _user);
    await _platform.initializePlatform();
    _platform.setupPlatformSpecificCommands(_command);

    _dadJokesManager = DadJokesManager(platform: _platform);
    _youtubeManager = YoutubeManager(platform: _platform, apiKey: youtubeKey);
    _conversatorManager = ConversatorManager(platform: _platform, db: _db, conversatorApiKey: conversatorKey);
    _generalManager = GeneralManager(platform: _platform, chat: _chat, repositoryUrl: repoUrl);
    _panoramaManager = PanoramaManager(platform: _platform, chat: _chat, db: _db)..initialize();
    _userManager = UserManager(platform: _platform, db: _db)..initialize();
    _reputationManager = ReputationManager(platform: _platform, db: _db, chat: _chat)..initialize();

    _chatManager = ChatManager(platform: _platform, db: _db);
    await _chatManager.initialize();

    _weatherManager = WeatherManager(platform: _platform, chat: _chat, db: _db, openweatherKey: openweatherKey);
    await _weatherManager.initialize();

    _setupCommands();
    // TODO: check if these work
    // _subscribeToUserUpdates();
    // _subscribeToWeatherUpdates();
    // _subscribeToPanoramaNews();

    await _platform.postStart();
  }

  void _setupCommands() {
    _platform.setupCommand(BotCommand(
        command: 'addcity',
        description: '[U] Add city to the watchlist',
        wrapper: _command.userCommand,
        withParameters: true,
        successCallback: _weatherManager.addCity));

    _platform.setupCommand(BotCommand(
        command: 'removecity',
        description: '[U] Remove city from the watchlist',
        wrapper: _command.userCommand,
        withParameters: true,
        successCallback: _weatherManager.removeCity));

    _platform.setupCommand(BotCommand(
        command: 'watchlist',
        description: '[U] Get weather watchlist',
        wrapper: _command.userCommand,
        successCallback: _weatherManager.getWeatherWatchlist));

    _platform.setupCommand(BotCommand(
        command: 'getweather',
        description: '[U] Get weather for city',
        wrapper: _command.userCommand,
        withParameters: true,
        successCallback: _weatherManager.getWeatherForCity));

    _platform.setupCommand(BotCommand(
        command: 'setnotificationhour',
        description: '[M] Set time for weather notifications',
        wrapper: _command.moderatorCommand,
        withParameters: true,
        successCallback: _weatherManager.setWeatherNotificationHour));

    _platform.setupCommand(BotCommand(
        command: 'write',
        description: '[M] Write message to the chat on behalf of the bot',
        wrapper: _command.moderatorCommand,
        withParameters: true,
        successCallback: _chatManager.writeToChat));

    _platform.setupCommand(BotCommand(
        command: 'updatemessage',
        description: '[A] Post update message',
        wrapper: _command.adminCommand,
        successCallback: _generalManager.postUpdateMessage));

    _platform.setupCommand(BotCommand(
        command: 'sendnews',
        description: '[U] Send news to the chat',
        wrapper: _command.userCommand,
        successCallback: _panoramaManager.sendNewsToChat));

    _platform.setupCommand(BotCommand(
        command: 'sendjoke',
        description: '[U] Send joke to the chat',
        wrapper: _command.userCommand,
        successCallback: _dadJokesManager.sendJoke));

    _platform.setupCommand(BotCommand(
        command: 'increp',
        description: '[U] Increase reputation for the user',
        wrapper: _command.userCommand,
        withOtherUserIds: true,
        successCallback: _reputationManager.increaseReputation));

    _platform.setupCommand(BotCommand(
        command: 'decrep',
        description: '[U] Decrease reputation for the user',
        wrapper: _command.userCommand,
        withOtherUserIds: true,
        successCallback: _reputationManager.decreaseReputation));

    _platform.setupCommand(BotCommand(
        command: 'replist',
        description: '[U] Send reputation list to the chat',
        wrapper: _command.userCommand,
        successCallback: _reputationManager.sendReputationList));

    _platform.setupCommand(BotCommand(
        command: 'searchsong',
        description: '[U] Search song on YouTube',
        wrapper: _command.userCommand,
        withParameters: true,
        successCallback: _youtubeManager.searchSong));

    _platform.setupCommand(BotCommand(
        command: 'ask',
        description: '[U] Ask for advice or anything else from the Conversator',
        wrapper: _command.userCommand,
        conversatorCommand: true,
        successCallback: _conversatorManager.getConversationReply));

    _platform.setupCommand(BotCommand(
        command: 'na',
        description: '[U] Check if bot is alive',
        wrapper: _command.userCommand,
        successCallback: _generalManager.postHealthCheck));

    _platform.setupCommand(BotCommand(
        command: 'initialize',
        description: '[A] Initialize new chat',
        wrapper: _command.adminCommand,
        successCallback: _chatManager.createChat));

    _platform.setupCommand(BotCommand(
        command: 'adduser',
        description: '[M] Add new user to the bot',
        wrapper: _command.moderatorCommand,
        withOtherUserIds: true,
        successCallback: _userManager.addUser));

    _platform.setupCommand(BotCommand(
        command: 'removeuser',
        description: '[M] Remove user from the bot',
        wrapper: _command.moderatorCommand,
        withOtherUserIds: true,
        successCallback: _userManager.removeUser));

    _platform.setupCommand(BotCommand(
        command: 'createreputation',
        description: '[A] Create reputation for the user',
        wrapper: _command.adminCommand,
        withOtherUserIds: true,
        successCallback: _reputationManager.createReputation));

    _platform.setupCommand(BotCommand(
        command: 'createweather',
        description: '[A] Activate weather module for the chat',
        wrapper: _command.adminCommand,
        successCallback: _weatherManager.createWeather));

    _platform.setupCommand(BotCommand(
        command: 'setswearwordsconfig',
        description: '[A] Set swearwords config for the chat',
        wrapper: _command.adminCommand,
        withParameters: true,
        successCallback: _chatManager.setSwearwordsConfig));
  }
}
