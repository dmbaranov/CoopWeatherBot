import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/config.dart';

import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/access_level.dart';

import 'package:weather/src/modules/modules_mediator.dart';
import 'package:weather/src/modules/manager_factory.dart';
import 'package:weather/src/modules/chat/chat_manager.dart';
import 'package:weather/src/modules/user/user_manager.dart';
import 'package:weather/src/modules/weather/weather_manager.dart';
import 'package:weather/src/modules/panorama/panorama_manager.dart';
import 'package:weather/src/modules/dadjokes/dadjokes_manager.dart';
import 'package:weather/src/modules/reputation/reputation_manager.dart';
import 'package:weather/src/modules/youtube/youtube_manager.dart';
import 'package:weather/src/modules/conversator/conversator_manager.dart';
import 'package:weather/src/modules/general/general_manager.dart';
import 'package:weather/src/modules/accordion_poll/accordion_poll_manager.dart';
import 'package:weather/src/modules/command_statistics/command_statistics_manager.dart';
import 'package:weather/src/modules/check_reminder/check_reminder_manager.dart';

class Bot {
  final Config _config;
  late Platform _platform;

  late UserManager _userManager;
  late WeatherManager _weatherManager;
  late DadJokesManager _dadJokesManager;
  late PanoramaManager _panoramaManager;
  late ReputationManager _reputationManager;
  late YoutubeManager _youtubeManager;
  late ConversatorManager _conversatorManager;
  late ChatManager _chatManager;
  late GeneralManager _generalManager;
  late AccordionPollManager _accordionPollManager;
  late CommandStatisticsManager _commandStatisticsManager;
  late CheckReminderManager _checkReminderManager;

  Bot() : _config = getIt<Config>();

  Future<void> startBot() async {
    var modulesMediator = ModulesMediator();

    _platform = Platform(chatPlatform: _config.chatPlatform, modulesMediator: modulesMediator)..initialize();

    var managerFactory = ManagerFactory(platform: _platform, modulesMediator: modulesMediator);

    _dadJokesManager = managerFactory.createManager<DadJokesManager>();
    _youtubeManager = managerFactory.createManager<YoutubeManager>();
    _conversatorManager = managerFactory.createManager<ConversatorManager>();
    _generalManager = managerFactory.createManager<GeneralManager>();
    _chatManager = managerFactory.createManager<ChatManager>();
    _panoramaManager = managerFactory.createManager<PanoramaManager>();
    _userManager = managerFactory.createManager<UserManager>();
    _reputationManager = managerFactory.createManager<ReputationManager>();
    _weatherManager = managerFactory.createManager<WeatherManager>();
    _accordionPollManager = managerFactory.createManager<AccordionPollManager>();
    _commandStatisticsManager = managerFactory.createManager<CommandStatisticsManager>();
    _checkReminderManager = managerFactory.createManager<CheckReminderManager>();

    _setupCommands();

    await _platform.postStart();
  }

  void _setupCommands() {
    _platform.setupCommand(BotCommand(
        command: 'addcity',
        description: '[U] Add city to the watchlist',
        accessLevel: AccessLevel.user,
        withParameters: true,
        onSuccess: _weatherManager.addCity));

    _platform.setupCommand(BotCommand(
        command: 'removecity',
        description: '[U] Remove city from the watchlist',
        accessLevel: AccessLevel.user,
        withParameters: true,
        onSuccess: _weatherManager.removeCity));

    _platform.setupCommand(BotCommand(
        command: 'watchlist',
        description: '[U] Get weather watchlist',
        accessLevel: AccessLevel.user,
        onSuccess: _weatherManager.getWeatherWatchlist));

    _platform.setupCommand(BotCommand(
        command: 'getweather',
        description: '[U] Get weather for city',
        accessLevel: AccessLevel.user,
        withParameters: true,
        onSuccess: _weatherManager.getWeatherForCity));

    _platform.setupCommand(BotCommand(
        command: 'setnotificationhour',
        description: '[M] Set time for weather notifications',
        accessLevel: AccessLevel.moderator,
        withParameters: true,
        onSuccess: _weatherManager.setWeatherNotificationHour));

    _platform.setupCommand(BotCommand(
        command: 'write',
        description: '[M] Write message to the chat on behalf of the bot',
        accessLevel: AccessLevel.moderator,
        withParameters: true,
        onSuccess: _chatManager.writeToChat));

    _platform.setupCommand(BotCommand(
        command: 'updatemessage',
        description: '[A] Post update message',
        accessLevel: AccessLevel.admin,
        onSuccess: _generalManager.postUpdateMessage));

    _platform.setupCommand(BotCommand(
        command: 'sendnews',
        description: '[U] Send news to the chat',
        accessLevel: AccessLevel.user,
        onSuccess: _panoramaManager.sendNewsToChat));

    _platform.setupCommand(BotCommand(
        command: 'sendjoke',
        description: '[U] Send joke to the chat',
        accessLevel: AccessLevel.user,
        onSuccess: _dadJokesManager.sendJoke));

    _platform.setupCommand(BotCommand(
        command: 'increp',
        description: '[U] Increase reputation for the user',
        accessLevel: AccessLevel.user,
        withOtherUser: true,
        onSuccess: _reputationManager.increaseReputation));

    _platform.setupCommand(BotCommand(
        command: 'decrep',
        description: '[U] Decrease reputation for the user',
        accessLevel: AccessLevel.user,
        withOtherUser: true,
        onSuccess: _reputationManager.decreaseReputation));

    _platform.setupCommand(BotCommand(
        command: 'replist',
        description: '[U] Send reputation list to the chat',
        accessLevel: AccessLevel.user,
        onSuccess: _reputationManager.sendReputationList));

    _platform.setupCommand(BotCommand(
        command: 'searchsong',
        description: '[U] Search song on YouTube',
        accessLevel: AccessLevel.user,
        withParameters: true,
        onSuccess: _youtubeManager.searchSong));

    _platform.setupCommand(BotCommand(
        command: 'ask',
        description: '[U] Ask for advice or anything else from the Conversator',
        accessLevel: AccessLevel.user,
        conversatorCommand: true,
        onSuccess: _conversatorManager.getRegularConversatorReply));

    _platform.setupCommand(BotCommand(
        command: 'theask',
        description: '[U][Limited] Ask for advice or anything else from the more advanced Conversator',
        accessLevel: AccessLevel.user,
        conversatorCommand: true,
        onSuccess: _conversatorManager.getAdvancedConversatorReply));

    _platform.setupCommand(BotCommand(
        command: 'na',
        description: '[U] Check if bot is alive',
        accessLevel: AccessLevel.user,
        onSuccess: _generalManager.postHealthCheck));

    _platform.setupCommand(BotCommand(
        command: 'initialize', description: '[A] Initialize new chat', accessLevel: AccessLevel.admin, onSuccess: _chatManager.createChat));

    _platform.setupCommand(BotCommand(
        command: 'adduser',
        description: '[M] Add new user to the bot',
        accessLevel: AccessLevel.moderator,
        withOtherUser: true,
        onSuccess: _userManager.addUser));

    _platform.setupCommand(BotCommand(
        command: 'removeuser',
        description: '[M] Remove user from the bot',
        accessLevel: AccessLevel.moderator,
        withOtherUser: true,
        onSuccess: _userManager.removeUser));

    _platform.setupCommand(BotCommand(
        command: 'createreputation',
        description: '[A] Create reputation for the user',
        accessLevel: AccessLevel.admin,
        withOtherUser: true,
        onSuccess: _reputationManager.createReputation));

    _platform.setupCommand(BotCommand(
        command: 'createweather',
        description: '[A] Activate weather module for the chat',
        accessLevel: AccessLevel.admin,
        onSuccess: _weatherManager.createWeather));

    _platform.setupCommand(BotCommand(
        command: 'setswearwordsconfig',
        description: '[A] Set swearwords config for the chat',
        accessLevel: AccessLevel.admin,
        withParameters: true,
        onSuccess: _chatManager.setSwearwordsConfig));

    _platform.setupCommand(BotCommand(
        command: 'watchlistweather',
        description: '[U] Get weather for each city in the watchlist',
        accessLevel: AccessLevel.user,
        onSuccess: _weatherManager.getWatchlistWeather));

    _platform.setupCommand(BotCommand(
        command: 'accordion',
        description: '[U] Start vote for the freshness of the content',
        accessLevel: AccessLevel.user,
        withOtherUser: true,
        onSuccess: _accordionPollManager.startAccordionPoll));

    _platform.setupCommand(BotCommand(
        command: 'getchatcommandstatistics',
        description: '[U] Get command invocation statistics for the chat',
        accessLevel: AccessLevel.user,
        onSuccess: _commandStatisticsManager.getChatCommandInvocations));

    _platform.setupCommand(BotCommand(
        command: 'getusercommandstatistics',
        description: '[U] Get command invocation statistics for the user',
        accessLevel: AccessLevel.user,
        withOtherUser: true,
        onSuccess: _commandStatisticsManager.getUserCommandInvocations));

    _platform.setupCommand(BotCommand(
        command: 'check',
        description: '[U] Remind about something after specified period',
        accessLevel: AccessLevel.user,
        withParameters: true,
        onSuccess: _checkReminderManager.checkMessage));
  }
}
