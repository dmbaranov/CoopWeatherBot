import 'package:collection/collection.dart';
import 'package:postgres/postgres.dart';
import 'package:meta/meta.dart';

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

  @protected
  late Platform platform;
  @protected
  late DatabaseManager dbManager;
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
      {required this.platformName,
      required this.botToken,
      required this.adminId,
      required this.repoUrl,
      required this.openweatherKey,
      required this.youtubeKey,
      required this.conversatorKey,
      required this.dbConnection});

  Future<void> startBot() async {
    dbManager = DatabaseManager(dbConnection);
    await dbManager.initialize();

    platform = Platform(chatPlatform: platformName, token: botToken);

    dadJokes = DadJokes();
    youtube = Youtube(youtubeKey);
    conversator = Conversator(dbManager: dbManager, conversatorApiKey: conversatorKey);
    accordionPoll = AccordionPoll();
    cm = CommandsManager(adminId: adminId, dbManager: dbManager);

    chatManager = ChatManager(dbManager: dbManager);
    await chatManager.initialize();

    panoramaNews = PanoramaNews(dbManager: dbManager);
    panoramaNews.initialize();

    userManager = UserManager(dbManager: dbManager);
    userManager.initialize();

    reputation = Reputation(dbManager: dbManager);
    reputation.initialize();

    weatherManager = WeatherManager(dbManager: dbManager, openweatherKey: openweatherKey);
    await weatherManager.initialize();

    await platform.initializePlatform();
    platform.setupPlatformSpecificCommands(cm);

    _setupCommands();
    _subscribeToUserUpdates();

    await platform.postStart();
  }

  void _setupCommands() {
    platform.setupCommand(
        Command(command: 'na', description: '[U] Check if bot is alive', wrapper: cm.userCommand, successCallback: _healthCheck));

    platform.setupCommand(Command(
        command: 'ask',
        description: '[U] Ask for advice or anything else from the Conversator',
        wrapper: cm.userCommand,
        conversatorCommand: true,
        successCallback: _askConversator));
  }

  void _subscribeToUserUpdates() {
    userManager.userManagerStream.listen((_) async {
      var allPlatformChatIds = await chatManager.getAllChatIdsForPlatform(platformName);

      await Future.forEach(allPlatformChatIds, (chatId) async {
        var chatUsers = await userManager.getUsersForChat(chatId);

        await Future.forEach(chatUsers, (chatUser) async {
          await Future.delayed(Duration(seconds: 1));

          var platformUserPremiumStatus = await platform.getUserPremiumStatus(chatId, chatUser.id);

          if (chatUser.isPremium != platformUserPremiumStatus) {
            print('Updating premium status for ${chatUser.id}');
            await userManager.updatePremiumStatus(chatUser.id, platformUserPremiumStatus);
          }
        });
      });
    });
  }

  bool _parametersCheck(MessageEvent event, [int numberOfParameters = 1]) {
    if (event.parameters.whereNot((parameter) => parameter.isEmpty).length < numberOfParameters) {
      platform.sendMessage(event.chatId, chatManager.getText(event.chatId, 'general.something_went_wrong'));

      return false;
    }

    return true;
  }

  void _healthCheck(MessageEvent event) async {
    await platform.sendMessage(event.chatId, chatManager.getText(event.chatId, 'general.bot_is_alive'));
  }

  @protected
  void _askConversator(MessageEvent event) async {
    if (!_parametersCheck(event)) return;

    var parentMessageId = event.parameters[0];
    var currentMessageId = event.parameters[1];
    var message = event.parameters[2];

    var response = await conversator.getConversationReply(
        chatId: event.chatId, parentMessageId: parentMessageId, currentMessageId: currentMessageId, message: message);

    var conversatorResponseMessage = await platform.sendMessage(event.chatId, response);
    var conversatorResponseMessageId = platform.getMessageId(conversatorResponseMessage);
    var conversationId = await conversator.getConversationId(event.chatId, parentMessageId);

    await conversator.saveConversationMessage(
        chatId: event.chatId,
        conversationId: conversationId,
        currentMessageId: conversatorResponseMessageId,
        message: response,
        fromUser: false);
  }
}
