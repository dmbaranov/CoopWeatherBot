import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import 'package:weather/src/modules/reputation.dart';

import './bot.dart';

ChatCommand getIncreaseReputationCommand(DiscordBot self) {
  return ChatCommand('increp', 'Increase reputation for the user', (IChatContext context, IMember who) async {
    await context.respond(MessageBuilder.empty());
    var from = context.user.id.toString();
    var to = who.user.id.toString();

    var result = await self.reputation.updateReputation(from, to, 'increase');

    await context.respond(MessageBuilder.content(result));
  });
}

ChatCommand getDecreaseReputationCommand(DiscordBot self) {
  return ChatCommand('decrep', 'Increase reputation for the user', (IChatContext context, IMember who) async {
    await context.respond(MessageBuilder.empty());
    var from = context.user.id.toString();
    var to = who.user.id.toString();

    var result = await self.reputation.updateReputation(from, to, 'decrease');

    await context.respond(MessageBuilder.content(result));
  });
}

ChatCommand getReputationListCommand(DiscordBot self) {
  return ChatCommand('replist', 'Get current reputation', (IChatContext context) async {
    await context.respond(MessageBuilder.empty());

    var reputationMessage = self.reputation.getReputationMessage();

    await context.respond(MessageBuilder.content(reputationMessage));
  });
}

ChatCommand getGenerateReputationUsersCommand(DiscordBot self) {
  return ChatCommand('setrepusers', 'Update reputation users', (IChatContext context) async {
    await context.respond(MessageBuilder.empty());

    var reputationUsers = self.users
        .map((rawUser) => ReputationUser.fromJson({'userId': rawUser.id.toString(), 'reputation': 0, 'fullName': rawUser.username}))
        .toList();

    await self.reputation.setUsers(reputationUsers);
    await context.respond(MessageBuilder.content(self.sm.get('reputation_users_updated')));
  }, checks: [self.isAdminCheck()]);
}

ChatCommand addWeatherCity(DiscordBot self) {
  return ChatCommand('addcity', 'Add city to receive periodic updates about the weather', (IChatContext context, String city) async {
    await context.respond(MessageBuilder.empty());

    var addedSuccessfully = await self.weather.addCity(city);

    if (addedSuccessfully) {
      await context.respond(MessageBuilder.content(self.sm.get('cities_list_updated')));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('cities_list_update_failed')));
    }
  });
}

ChatCommand removeWeatherCity(DiscordBot self) {
  return ChatCommand('removecity', 'Remove city to stop receiving periodic updates about the weather',
      (IChatContext context, String city) async {
    await context.respond(MessageBuilder.empty());

    var removedSuccessfully = await self.weather.removeCity(city);

    if (removedSuccessfully) {
      await context.respond(MessageBuilder.content(self.sm.get('cities_list_updated')));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('cities_list_update_failed')));
    }
  });
}

ChatCommand getWeatherWatchlist(DiscordBot self) {
  return ChatCommand('getcities', 'Get the list of cities for which weather is being tracked', (IChatContext context) async {
    await context.respond(MessageBuilder.empty());

    var citiesList = await self.weather.getWatchList();

    if (citiesList.isNotEmpty) {
      await context.respond(MessageBuilder.content(citiesList));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('get_weather_cities_failed')));
    }
  });
}

ChatCommand getWeatherForCity(DiscordBot self) {
  return ChatCommand('getweather', 'Get weather for the provided city', (IChatContext context, String city) async {
    await context.respond(MessageBuilder.empty());

    var temperature = await self.weather.getWeatherForCity(city);

    if (temperature == null) {
      await context.respond(MessageBuilder.content(self.sm.get('get_weather_for_city_failed')));
      return;
    }

    await context.respond(MessageBuilder.content(self.sm.get('weather_in_city', {'city': city, 'temp': temperature.toString()})));
  });
}

ChatCommand setWeatherNotificationHour(DiscordBot self) {
  return ChatCommand('setweatherhour', 'Set notification hour for weather', (IChatContext context, String hour) async {
    await context.respond(MessageBuilder.empty());

    var setSuccessfully = self.weather.setNotificationsHour(int.parse(hour));

    if (setSuccessfully) {
      await context.respond(MessageBuilder.content(self.sm.get('weather_notification_hour_updated')));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('weather_notification_update_failed')));
    }
  });
}

ChatCommand write(DiscordBot self) {
  return ChatCommand('write', 'Write something to the channel', (IChatContext context, String message) async {
    await context.respond(MessageBuilder.empty());

    await self.bot.httpEndpoints.sendMessage(Snowflake(self.channelId), MessageBuilder.content(message));
  }, checks: [self.isAdminCheck()]);
}
