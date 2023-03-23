import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:cron/cron.dart';
import 'package:postgres/postgres.dart';
import 'package:weather/src/modules/database-manager/database_manager.dart';

import 'package:weather/src/modules/swearwords_manager.dart';
import 'package:weather/src/modules/reputation.dart';
import 'package:weather/src/modules/conversator.dart';
import 'package:weather/src/modules/weather_manager.dart';
import 'package:weather/src/modules/user_manager.dart';
import 'package:weather/src/modules/chat_manager.dart';

import './commands.dart';

class DiscordBot {
  final String token;
  final String guildId;
  final String channelId;
  final String adminId;
  final String openweatherKey;
  final String conversatorKey;
  final PostgreSQLConnection dbConnection;
  late INyxxWebsocket bot;
  late DatabaseManager dbManager;
  late SwearwordsManager sm;
  late UserManager userManager;
  late Reputation reputation;
  late WeatherManager weatherManager;
  late Conversator conversator;
  late ChatManager chatManager;

  DiscordBot(
      {required this.token,
      required this.adminId,
      required this.guildId,
      required this.channelId,
      required this.openweatherKey,
      required this.conversatorKey,
      required this.dbConnection});

  void startBot() async {
    bot = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.all);

    bot
      ..registerPlugin(Logging())
      ..registerPlugin(CliIntegration())
      ..registerPlugin(IgnoreExceptions())
      ..registerPlugin(_setupCommands());

    dbManager = DatabaseManager(dbConnection);
    await dbManager.initialize();

    await bot.connect();

    sm = SwearwordsManager();
    await sm.initialize();

    userManager = UserManager(dbManager: dbManager);
    userManager.initialize();

    reputation = Reputation(dbManager: dbManager);
    reputation.initialize();

    weatherManager = WeatherManager(openweatherKey: openweatherKey, dbManager: dbManager);
    weatherManager.initialize();

    conversator = Conversator(conversatorKey);

    chatManager = ChatManager(dbManager: dbManager);

    _startHeroCheckJob();
  }

  void _startHeroCheckJob() async {
    // TODO: onlineUsers are returned for a single chat only. Fix this + make this job configurable per chat
    Cron().schedule(Schedule.parse('0 4 * * 6,0'), () async {
      await Process.run('${Directory.current.path}/generate-online', []);

      var onlineFile = File('assets/online');
      var onlineUsers = await onlineFile.readAsLines();

      var chats = await chatManager.getAllChatIds(ChatPlatform.discord);

      await Future.forEach(chats, (chatId) async {
        var guild = await bot.httpEndpoints.fetchGuild(Snowflake(chatId));
        var channelId = guild.systemChannel?.id.toString() ?? '';

        if (onlineUsers.isEmpty) {
          var message = sm.get('hero.users_at_five.no_users');

          return bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(message));
        }

        var heroesMessage = sm.get('hero.users.at_five.list');
        var chatUsers = await userManager.getUsersForChat(chatId);

        onlineUsers.forEach((userId) {
          var onlineUser = chatUsers.firstWhereOrNull((user) => user.id == userId);

          if (onlineUser != null) {
            heroesMessage += onlineUser.name;
            heroesMessage += '\n';
          }
        });

        await bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(heroesMessage));
      });

      await onlineFile.delete();
    });
  }

  // TODO: add command to move all from one channel to another
  CommandsPlugin _setupCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!', guild: Snowflake(guildId));

    commands
      ..addCommand(increaseReputation(this))
      ..addCommand(decreaseReputation(this))
      ..addCommand(getReputationList(this))
      ..addCommand(addWeatherCity(this))
      ..addCommand(removeWeatherCity(this))
      ..addCommand(getWeatherWatchlist(this))
      ..addCommand(getWeatherForCity(this))
      ..addCommand(setWeatherNotificationHour(this))
      ..addCommand(write(this))
      ..addCommand(moveAllToDifferentChannel(this))
      ..addCommand(getConversatorReply(this))
      ..addCommand(addUser(this))
      ..addCommand(removeUser(this))
      ..addCommand(initChat(this))
      ..addCommand(createReputation(this))
      ..addCommand(createWeather(this));

    commands.onCommandError.listen((error) {
      if (error is CheckFailedException) {
        error.context.respond(MessageBuilder.content(sm.get('general.no_access')));
      }
    });

    return commands;
  }

  Check isAdminCheck() {
    return Check((context) => context.user.id == adminId.toSnowflake());
  }

  Check isVerifiedServerCheck() {
    return Check((context) => context.channel.id == Snowflake(channelId));
  }

  Future<List<UMUser>> getChatUsers(String chatId) async {
    List<UMUser> users = [];
    var guild = await bot.fetchGuild(Snowflake(chatId));
    var userIds = [];
    var usersStream = guild.fetchMembers(limit: 999).listen((userId) => userIds.add(userId));

    await Future.wait([usersStream.asFuture()]);

    await Future.forEach(userIds, (userId) async {
      await Future.delayed(Duration(milliseconds: 500));

      var user = await bot.fetchUser(Snowflake(userId));

      if (!user.bot) {
        users.add(UMUser(id: user.id.toString(), name: user.username, chatId: chatId));
      }
    });

    return users;
  }
}
