import 'dart:async';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import 'modules/swearwords_manager.dart';
import 'modules/reputation.dart';
import 'modules/weather.dart';

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
    // startWeatherPolling();
  }

  void startWeatherPolling() {
    weather.weatherStream.listen((weatherString) {
      bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(weatherString));
    });
  }

  // TODO: add command to move all from one channel to another
  CommandsPlugin _setupCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!', guild: Snowflake(guildId));

    commands
      ..addCommand(_getIncreaseReputationCommand())
      ..addCommand(_getDecreaseReputationCommand())
      ..addCommand(_getReputationListCommand())
      ..addCommand(_getGenerateReputationUsersCommand())
      ..addCommand(_addWeatherCity())
      ..addCommand(_removeWeatherCity())
      ..addCommand(_getWeatherWatchlist())
      ..addCommand(_getWeatherForCity())
      ..addCommand(_setWeatherNotificationHour())
      ..addCommand(_write());

    return commands;
  }

  Future<void> _updateUsersList() async {
    var guild = await bot.fetchGuild(Snowflake(guildId));
    var userIds = [];
    var usersStream = guild.fetchMembers(limit: 999).listen((userId) => userIds.add(userId));

    await Future.wait([usersStream.asFuture()]);

    users = await Future.wait(userIds.map((userId) async => await bot.fetchUser(Snowflake(userId))));
    users = users.where((user) => user.bot == false).toList();
  }

  ChatCommand _getIncreaseReputationCommand() {
    return ChatCommand('increp', 'Increase reputation for the user', (IChatContext context, String who) async {
      await context.respond(MessageBuilder.empty());
      var from = context.user.id.toString();
      var to = who.substring(2, who.length - 1);

      var result = await reputation.updateReputation(from, to, 'increase');

      await context.respond(MessageBuilder.content(result));
    });
  }

  ChatCommand _getDecreaseReputationCommand() {
    return ChatCommand('decrep', 'Increase reputation for the user', (IChatContext context, String who) async {
      await context.respond(MessageBuilder.empty());
      var from = context.user.id.toString();
      var to = who.substring(2, who.length - 1);

      var result = await reputation.updateReputation(from, to, 'decrease');

      await context.respond(MessageBuilder.content(result));
    });
  }

  ChatCommand _getReputationListCommand() {
    return ChatCommand('replist', 'Get current reputation', (IChatContext context) async {
      await context.respond(MessageBuilder.empty());

      var reputationMessage = reputation.getReputationMessage();

      await context.respond(MessageBuilder.content(reputationMessage));
    });
  }

  ChatCommand _getGenerateReputationUsersCommand() {
    return ChatCommand('setrepusers', 'Update reputation users', (IChatContext context) async {
      await context.respond(MessageBuilder.empty());

      // TODO: make a helper function
      if (context.user.id.toString() != adminId) {
        return context.respond(MessageBuilder.content(sm.get('you_are_not_an_admin')));
      }

      var reputationUsers = users
          .map((rawUser) => ReputationUser.fromJson({'userId': rawUser.id.toString(), 'reputation': 0, 'fullName': rawUser.username}))
          .toList();

      await reputation.setUsers(reputationUsers);
      await context.respond(MessageBuilder.content(sm.get('reputation_users_updated')));
    });
  }

  ChatCommand _addWeatherCity() {
    return ChatCommand('addcity', 'Add city to receive periodic updates about the weather', (IChatContext context, String city) async {
      await context.respond(MessageBuilder.empty());

      var addedSuccessfully = await weather.addCity(city);

      if (addedSuccessfully) {
        await context.respond(MessageBuilder.content(sm.get('cities_list_updated')));
      } else {
        await context.respond(MessageBuilder.content(sm.get('cities_list_update_failed')));
      }
    });
  }

  ChatCommand _removeWeatherCity() {
    return ChatCommand('removecity', 'Remove city to stop receiving periodic updates about the weather',
        (IChatContext context, String city) async {
      await context.respond(MessageBuilder.empty());

      var removedSuccessfully = await weather.removeCity(city);

      if (removedSuccessfully) {
        await context.respond(MessageBuilder.content(sm.get('cities_list_updated')));
      } else {
        await context.respond(MessageBuilder.content(sm.get('cities_list_update_failed')));
      }
    });
  }

  ChatCommand _getWeatherWatchlist() {
    return ChatCommand('getcities', 'Get the list of cities for which weather is being tracked', (IChatContext context) async {
      await context.respond(MessageBuilder.empty());

      var citiesList = await weather.getWatchList();

      if (citiesList.isNotEmpty) {
        await context.respond(MessageBuilder.content(citiesList));
      } else {
        await context.respond(MessageBuilder.content(sm.get('get_weather_cities_failed')));
      }
    });
  }

  ChatCommand _getWeatherForCity() {
    return ChatCommand('getweather', 'Get weather for the provided city', (IChatContext context, String city) async {
      await context.respond(MessageBuilder.empty());

      var temperature = await weather.getWeatherForCity(city);

      if (temperature == null) {
        await context.respond(MessageBuilder.content(sm.get('get_weather_for_city_failed')));
        return;
      }

      await context.respond(MessageBuilder.content(sm.get('weather_in_city', {'city': city, 'temp': temperature.toString()})));
    });
  }

  ChatCommand _setWeatherNotificationHour() {
    return ChatCommand('setweatherhour', 'Set notification hour for weather', (IChatContext context, String hour) async {
      await context.respond(MessageBuilder.empty());

      var setSuccessfully = weather.setNotificationsHour(int.parse(hour));

      if (setSuccessfully) {
        await context.respond(MessageBuilder.content(sm.get('weather_notification_hour_updated')));
      } else {
        await context.respond(MessageBuilder.content(sm.get('weather_notification_update_failed')));
      }
    });
  }

  ChatCommand _write() {
    return ChatCommand('write', 'Write something to the channel', (IChatContext context, String message) async {
      await context.respond(MessageBuilder.empty());

      if (context.user.id.toString() != adminId) {
        return context.respond(MessageBuilder.content(sm.get('you_are_not_an_admin')));
      }

      await bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(message));
    });
  }
}
