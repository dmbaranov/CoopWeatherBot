import 'dart:async';
import 'dart:io';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:cron/cron.dart';

import 'package:weather/src/modules/swearwords_manager.dart';
import 'package:weather/src/modules/reputation.dart';
import 'package:weather/src/modules/weather_manager.dart';
import 'package:weather/src/modules/user_manager.dart';

import './commands.dart';

class DiscordBot {
  final String token;
  final String guildId;
  final String channelId;
  final String adminId;
  final String openweatherKey;
  late INyxxWebsocket bot;
  late SwearwordsManager sm;
  late UserManager userManager;
  late Reputation reputation;
  late WeatherManager weatherManager;

  DiscordBot({required this.token, required this.adminId, required this.guildId, required this.channelId, required this.openweatherKey});

  void startBot() async {
    bot = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.all);

    bot
      ..registerPlugin(Logging())
      ..registerPlugin(CliIntegration())
      ..registerPlugin(IgnoreExceptions())
      ..registerPlugin(_setupCommands());

    await bot.connect();
    await _updateUsersList();

    sm = SwearwordsManager();
    await sm.initialize();

    userManager = UserManager();
    await userManager.initialize();

    reputation = Reputation(sm: sm, userManager: userManager);
    await reputation.initialize();

    weatherManager = WeatherManager(openweatherKey: openweatherKey);
    weatherManager.initialize();

    _startHeroCheckJob();
  }

  void _startHeroCheckJob() async {
    Cron().schedule(Schedule.parse('0 4 * * 6,0'), () async {
      await Process.run('${Directory.current.path}/generate-online', []);

      var onlineFile = File('assets/online');
      var onlineUsers = await onlineFile.readAsLines();

      if (onlineUsers.isEmpty) {
        var message = sm.get('no_users_online_at_five');

        return bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(message));
      }

      var heroesMessage = sm.get('users_online_at_five');

      onlineUsers.forEach((userId) {
        var onlineUser = userManager.users.firstWhere((user) => user.id == userId);

        heroesMessage += onlineUser.name;
        heroesMessage += '\n';
      });

      await bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(heroesMessage));

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
      ..addCommand(moveAllToDifferentChannel(this));

    commands.onCommandError.listen((error) {
      if (error is CheckFailedException) {
        error.context.respond(MessageBuilder.content(sm.get('you_are_not_an_admin')));
      }
    });

    return commands;
  }

  Check isAdminCheck() {
    return Check((context) => context.user.id == adminId.toSnowflake());
  }

  Future<void> _updateUsersList() async {
    var guild = await bot.fetchGuild(Snowflake(guildId));
    var userIds = [];
    var usersStream = guild.fetchMembers(limit: 999).listen((userId) => userIds.add(userId));

    await Future.wait([usersStream.asFuture()]);

    userIds.forEach((userId) async {
      var user = await bot.fetchUser(Snowflake(userId));

      userManager.addUser(UMUser(id: user.id.toString(), name: user.username));
    });
  }
}
