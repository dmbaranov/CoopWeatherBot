import 'dart:convert';
import 'dart:io';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:weather/src/modules/reputation.dart';

import './bot.dart';

ChatCommand increaseReputation(DiscordBot self) {
  return ChatCommand('increp', 'Increase reputation for the user', (IChatContext context, IMember who) async {
    var discordUser = await self.bot.fetchUser(who.id);

    await context.respond(MessageBuilder.content(discordUser.username));

    var chatId = context.guild?.id.toString() ?? '';
    var fromUserId = context.user.id.toString();
    var toUserId = who.user.id.toString();

    var changeResult = await self.reputation
        .updateReputation(chatId: chatId, fromUserId: fromUserId, toUserId: toUserId, change: ReputationChangeOption.increase);

    switch (changeResult) {
      case ReputationChangeResult.increaseSuccess:
        await context.respond(MessageBuilder.content(self.sm.get('reputation.change.increase_success')));
        break;
      case ReputationChangeResult.decreaseSuccess:
        await context.respond(MessageBuilder.content(self.sm.get('reputation.change.decrease_success')));
        break;
      case ReputationChangeResult.userNotFound:
        await context.respond(MessageBuilder.content(self.sm.get('reputation.change.user_not_found')));
        break;
      case ReputationChangeResult.selfUpdate:
        await context.respond(MessageBuilder.content(self.sm.get('reputation.change.self_update')));
        break;
      case ReputationChangeResult.notEnoughOptions:
        await context.respond(MessageBuilder.content(self.sm.get('reputation.change.not_enough_options')));
        break;
      case ReputationChangeResult.systemError:
        await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));
        break;
    }
  });
}

ChatCommand decreaseReputation(DiscordBot self) {
  return ChatCommand('decrep', 'Increase reputation for the user', (IChatContext context, IMember who) async {
    var discordUser = await self.bot.fetchUser(who.id);

    await context.respond(MessageBuilder.content(discordUser.username));

    var chatId = context.guild?.id.toString() ?? '';
    var fromUserId = context.user.id.toString();
    var toUserId = who.user.id.toString();

    var changeResult = await self.reputation
        .updateReputation(chatId: chatId, fromUserId: fromUserId, toUserId: toUserId, change: ReputationChangeOption.decrease);

    switch (changeResult) {
      case ReputationChangeResult.increaseSuccess:
        await context.respond(MessageBuilder.content(self.sm.get('reputation.change.increase_success')));
        break;
      case ReputationChangeResult.decreaseSuccess:
        await context.respond(MessageBuilder.content(self.sm.get('reputation.change.decrease_success')));
        break;
      case ReputationChangeResult.userNotFound:
        await context.respond(MessageBuilder.content(self.sm.get('reputation.change.user_not_found')));
        break;
      case ReputationChangeResult.selfUpdate:
        await context.respond(MessageBuilder.content(self.sm.get('reputation.change.self_update')));
        break;
      case ReputationChangeResult.notEnoughOptions:
        await context.respond(MessageBuilder.content(self.sm.get('reputation.change.not_enough_options')));
        break;
      case ReputationChangeResult.systemError:
        await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));
        break;
    }
  });
}

ChatCommand getReputationList(DiscordBot self) {
  return ChatCommand('replist', 'Get current reputation', (IChatContext context) async {
    await context.respond(MessageBuilder.empty());

    var chatId = context.guild?.id.toString() ?? '';
    var reputationData = await self.reputation.getReputationMessage(chatId);
    var reputationMessage = '';

    reputationData.forEach((reputation) {
      reputationMessage += self.sm.get('reputation.other.line', {'name': reputation.name, 'reputation': reputation.reputation.toString()});
    });

    if (reputationMessage.isEmpty) {
      await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('reputation.other.list', {'reputation': reputationMessage})));
    }
  });
}

ChatCommand addWeatherCity(DiscordBot self) {
  return ChatCommand('addcity', 'Add city to receive periodic updates about the weather', (IChatContext context, String city) async {
    await context.respond(MessageBuilder.empty());

    var chatId = context.guild?.id.toString() ?? '';
    var result = await self.weatherManager.addCity(chatId, city);

    if (result) {
      await context.respond(MessageBuilder.content(self.sm.get('weather.cities.added', {'city': city})));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));
    }
  });
}

ChatCommand removeWeatherCity(DiscordBot self) {
  return ChatCommand('removecity', 'Remove city to stop receiving periodic updates about the weather',
      (IChatContext context, String city) async {
    await context.respond(MessageBuilder.empty());

    var chatId = context.guild?.id.toString() ?? '';
    var result = await self.weatherManager.removeCity(chatId, city);

    if (result) {
      await context.respond(MessageBuilder.content(self.sm.get('weather.cities.removed', {'city': city})));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));
    }
  });
}

ChatCommand getWeatherWatchlist(DiscordBot self) {
  return ChatCommand('getcities', 'Get the list of cities for which weather is being tracked', (IChatContext context) async {
    await context.respond(MessageBuilder.empty());

    var chatId = context.guild?.id.toString() ?? '';
    var cities = await self.weatherManager.getWatchList(chatId);
    var citiesString = cities.join('\n');

    await context.respond(MessageBuilder.content(self.sm.get('weather.cities.watchlist', {'cities': citiesString})));
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

    var chatId = context.guild?.id.toString() ?? '';
    var result = await self.weatherManager.setNotificationHour(chatId, int.parse(hour));

    if (result) {
      await context.respond(MessageBuilder.content(self.sm.get('weather.other.notification_hour_set', {'hour': hour})));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));
    }
  });
}

ChatCommand write(DiscordBot self) {
  return ChatCommand('write', 'Write something to the channel', (IChatContext context, String message) async {
    await context.respond(MessageBuilder.content('Temporarily disabled'));

    // await self.bot.httpEndpoints.sendMessage(Snowflake(self.channelId), MessageBuilder.content(message));
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

    var chatId = context.guild?.id.toString() ?? '';

    usersToMove.forEach((user) {
      var builder = MemberBuilder()..channel = Snowflake(toChannel);

      self.bot.httpEndpoints.editGuildMember(Snowflake(chatId), Snowflake(user), builder: builder);
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
    await context.respond(MessageBuilder.empty());

    var discordUser = await self.bot.fetchUser(who.id);

    if (discordUser.bot) {
      print('Invalid user data');

      return;
    }

    var chatId = context.guild?.id.toString() ?? '';

    var addResult = await self.userManager.addUser(id: who.id.toString(), chatId: chatId, name: discordUser.username);

    if (addResult) {
      await context.respond(MessageBuilder.content(self.sm.get('user.user_added')));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));
    }
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

    var chatId = context.guild?.id.toString() ?? '';
    var removeResult = await self.userManager.removeUser(chatId, discordUser.id.toString());

    if (removeResult) {
      await context.respond(MessageBuilder.content(self.sm.get('user.user_removed')));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));
    }
  }, checks: [self.isAdminCheck()]);
}

ChatCommand initChat(DiscordBot self) {
  return ChatCommand('initialize', 'Initialize new chat', (IChatContext context) async {
    await context.respond(MessageBuilder.empty());

    var chatId = context.guild?.id.toString();
    var chatName = context.guild?.name.toString() ?? 'Unknown Discord guild';

    if (chatId == null) {
      await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));

      return;
    }

    var result = await self.chatManager.createChat(id: chatId, name: chatName);

    if (!result) {
      await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));

      return;
    }

    var chatUsers = await self.getChatUsers(chatId);

    await Future.forEach(chatUsers, (user) async {
      await self.userManager.addUser(id: user.id, chatId: user.chatId, name: user.name);
    });

    await context.respond(MessageBuilder.content(self.sm.get('general.success')));
  }, checks: [self.isAdminCheck()]);
}

ChatCommand createReputation(DiscordBot self) {
  return ChatCommand('createreputation', 'Create initial reputation for the chat', (IChatContext context) async {
    await context.respond(MessageBuilder.empty());

    var chatId = context.guild?.id.toString() ?? '';

    var users = await self.getChatUsers(chatId);

    await Future.forEach(users, (user) async {
      await self.reputation.createReputationData(chatId, user.id);
    });

    await context.respond(MessageBuilder.content(self.sm.get('general.success')));
  }, checks: [self.isAdminCheck()]);
}

ChatCommand createWeather(DiscordBot self) {
  return ChatCommand('createweather', 'Activate weather module for the chat', (IChatContext context) async {
    var chatId = context.guild?.id.toString() ?? '';

    var result = await self.weatherManager.createWeatherData(chatId);

    if (result) {
      await context.respond(MessageBuilder.content(self.sm.get('general.success')));
    } else {
      await context.respond(MessageBuilder.content(self.sm.get('general.something_went_wrong')));
    }
  });
}
