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
import 'package:weather/src/modules/accordion_poll.dart';
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
  late AccordionPoll _accordionPoll;
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

    _platform = Platform(chatPlatform: platformName, token: botToken);

    _dadJokes = DadJokes();
    _youtube = Youtube(youtubeKey);
    _conversator = Conversator(dbManager: _dbManager, conversatorApiKey: conversatorKey);
    _accordionPoll = AccordionPoll();
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

    await _platform.initializePlatform();
    _platform.setupPlatformSpecificCommands(_cm);

    _setupCommands();
    _subscribeToUserUpdates();

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
  }

  void _subscribeToUserUpdates() {
    _userManager.userManagerStream.listen((_) async {
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
    });
  }

  bool _parametersCheck(MessageEvent event, [int numberOfParameters = 1]) {
    if (event.parameters.whereNot((parameter) => parameter.isEmpty).length < numberOfParameters) {
      _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'general.something_went_wrong'));

      return false;
    }

    return true;
  }

  void _healthCheck(MessageEvent event) async {
    await _platform.sendMessage(event.chatId, _chatManager.getText(event.chatId, 'general.bot_is_alive'));
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
