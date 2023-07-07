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

    await platform.postStart();
  }

  void _setupCommands() {
    platform.setupCommand(
        Command(command: 'na', description: '[U] Check if bot is alive', wrapper: cm.userCommand, successCallback: healthCheck));
  }

  void healthCheck(MessageEvent event) async {
    await platform.sendMessage(event.chatId, chatManager.getText(event.chatId, 'general.bot_is_alive'));
  }
}
