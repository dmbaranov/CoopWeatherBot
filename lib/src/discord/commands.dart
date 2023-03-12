import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:weather/src/modules/user_manager.dart';

import './bot.dart';

ChatCommand increaseReputation(DiscordBot self) {
  return ChatCommand('increp', 'Increase reputation for the user', (IChatContext context, IMember who) async {
    // await context.respond(MessageBuilder.empty());
    // var fromUser = self.userManager.users.firstWhereOrNull((user) => user.id == context.user.id.toString());
    // var toUser = self.userManager.users.firstWhereOrNull((user) => user.id == who.user.id.toString());
    //
    // var result = await self.reputation.updateReputation(from: fromUser, to: toUser, type: 'increase');
    //
    // // TODO: check if instead of new message you can edit previous one
    // await context.respond(MessageBuilder.content(result));
  });
}

ChatCommand decreaseReputation(DiscordBot self) {
  return ChatCommand('decrep', 'Increase reputation for the user', (IChatContext context, IMember who) async {
    await context.respond(MessageBuilder.empty());
    // var fromUser = self.userManager.users.firstWhereOrNull((user) => user.id == context.user.id.toString());
    // var toUser = self.userManager.users.firstWhereOrNull((user) => user.id == who.user.id.toString());
    //
    // var result = await self.reputation.updateReputation(from: fromUser, to: toUser, type: 'decrease');
    //
    // await context.respond(MessageBuilder.content(result));
  });
}

ChatCommand getReputationList(DiscordBot self) {
  return ChatCommand('replist', 'Get current reputation', (IChatContext context) async {
    await context.respond(MessageBuilder.empty());

    var reputationMessage = self.reputation.getReputationMessage();

    await context.respond(MessageBuilder.content(reputationMessage));
  });
}

ChatCommand addWeatherCity(DiscordBot self) {
  return ChatCommand('addcity', 'Add city to receive periodic updates about the weather', (IChatContext context, String city) async {
    await context.respond(MessageBuilder.empty());

    var addedSuccessfully = await self.weatherManager.addCity(city);

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

    var removedSuccessfully = await self.weatherManager.removeCity(city);

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

    var citiesList = await self.weatherManager.getWatchList();

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

    var temperature = await self.weatherManager.getWeatherForCity(city);

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

    var setSuccessfully = self.weatherManager.setNotificationsHour(int.parse(hour));

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

ChatCommand moveAllToDifferentChannel(DiscordBot self) {
  return ChatCommand('moveall', 'Move all users from one voice channel to another',
      (IChatContext context, IChannel fromChannel, IChannel toChannel) async {
    await context.respond(MessageBuilder.empty());

    await Process.run('${Directory.current.path}/generate-channel-users', []);

    var channelUsersFile = File('assets/channels-users');
    var channelsWithUsersRaw = await channelUsersFile.readAsLines();

    Map<String, dynamic> channelsWithUsers = jsonDecode(channelsWithUsersRaw[0]);
    List usersToMove = channelsWithUsers[fromChannel.toString()];

    usersToMove.forEach((user) {
      var builder = MemberBuilder()..channel = Snowflake(toChannel);

      self.bot.httpEndpoints.editGuildMember(Snowflake(self.guildId), Snowflake(user), builder: builder);
    });

    await channelUsersFile.delete();
  }, checks: [self.isAdminCheck()]);
}

ChatCommand getConversatorReply(DiscordBot self) {
  return ChatCommand('ask', 'Ask for advice from the Conversator', (IChatContext context, String question) async {
    await context.respond(MessageBuilder.content(question));

    var reply = await self.conversator.getConversationReply(question);

    await context.respond(MessageBuilder.content(reply));
  }, checks: [self.isVerifiedServerCheck()]);
}

ChatCommand addUser(DiscordBot self) {
  return ChatCommand('adduser', 'Add user to the bot', (IChatContext context, IMember who) async {
    // await context.respond(MessageBuilder.empty());
    //
    // var discordUser = await self.bot.fetchUser(who.id);
    //
    // if (discordUser.bot) {
    //   print('Invalid user data');
    //
    //   return;
    // }
    //
    // var userToAdd = UMUser(id: who.id.toString(), name: discordUser.username);
    // var addResult = await self.userManager.addUser(userToAdd);
    //
    // if (addResult) {
    //   await context.respond(MessageBuilder.content('User added'));
    // } else {
    //   await context.respond(MessageBuilder.content('User not added'));
    // }
  }, checks: [self.isAdminCheck()]);
}

ChatCommand removeUser(DiscordBot self) {
  return ChatCommand('removeuser', 'Remove user from the bot', (IChatContext context, IMember who) async {
    await context.respond(MessageBuilder.empty());

    var discordUser = await self.bot.fetchUser(who.id);

    if (discordUser.bot) {
      print('Invalid user data');

      return;
    }

    var removeResult = await self.userManager.removeUser(discordUser.id.toString());

    if (removeResult) {
      await context.respond(MessageBuilder.content('User removed'));
    } else {
      await context.respond(MessageBuilder.content('User not removed'));
    }
  }, checks: [self.isAdminCheck()]);
}
