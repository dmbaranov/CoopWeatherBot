import 'dart:async';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import 'package:weather/src/modules/swearwords_manager.dart';
import 'package:weather/src/modules/reputation.dart';
import 'package:weather/src/modules/weather.dart';

import './commands.dart';

class DiscordBot {
  final String token;
  final String guildId;
  final String channelId;
  final String adminId;
  final String openweatherKey;
  late INyxxWebsocket bot;
  late List<IUser> users;
  late SwearwordsManager sm;
  late Reputation reputation;
  late Weather weather;

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
    await sm.initSwearwords();

    reputation = Reputation(sm: sm);
    await reputation.initReputation();

    weather = Weather(openweatherKey: openweatherKey);
    weather.initWeather();

    // It was decided to disable weather notifications for now
    // _subscribeToWeather();
  }

  void _subscribeToWeather() {
    weather.weatherStream.listen((weatherString) {
      bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(weatherString));
    });
  }

  // TODO: add command to move all from one channel to another
  CommandsPlugin _setupCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!', guild: Snowflake(guildId));

    commands
      ..addCommand(getIncreaseReputationCommand(this))
      ..addCommand(getDecreaseReputationCommand(this))
      ..addCommand(getReputationListCommand(this))
      ..addCommand(getGenerateReputationUsersCommand(this))
      ..addCommand(addWeatherCity(this))
      ..addCommand(removeWeatherCity(this))
      ..addCommand(getWeatherWatchlist(this))
      ..addCommand(getWeatherForCity(this))
      ..addCommand(setWeatherNotificationHour(this))
      ..addCommand(write(this));

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

    users = await Future.wait(userIds.map((userId) async => await bot.fetchUser(Snowflake(userId))));
    users = users.where((user) => user.bot == false).toList();
  }
}