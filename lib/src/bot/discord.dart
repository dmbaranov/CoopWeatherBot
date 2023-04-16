import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:cron/cron.dart';

import 'package:weather/src/bot/bot.dart';
import 'package:weather/src/modules/chat_manager.dart';
import 'package:weather/src/modules/commands_manager.dart';

class DiscordBot extends Bot<IChatContext> {
  final List<ChatCommand> _commands = [];
  late INyxxWebsocket bot;

  DiscordBot(
      {required super.botToken,
      required super.adminId,
      required super.repoUrl,
      required super.openweatherKey,
      required super.conversatorKey,
      required super.dbConnection,
      required super.youtubeKey});

  @override
  Future<void> startBot() async {
    await super.startBot();

    bot = NyxxFactory.createNyxxWebsocket(botToken, GatewayIntents.all);

    bot
      ..registerPlugin(Logging())
      ..registerPlugin(CliIntegration())
      ..registerPlugin(IgnoreExceptions())
      ..registerPlugin(_setupDiscordCommands());

    _startHeroCheckJob();

    await bot.connect();

    print('Discord bot has been started!');
  }

  @override
  Future<void> sendMessage(String chatId, String message) async {
    var guild = await bot.httpEndpoints.fetchGuild(Snowflake(chatId));
    var channelId = guild.systemChannel?.id.toString() ?? '';

    await bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(message));
  }

  @override
  void setupCommand(String command, CommandsWrapper cmCommandWrapper, MessageEventMapper<IChatContext> mapToMessageEvent,
      OnSuccessCallback onSuccessCallback,
      [String? description]) {
    _commands.add(ChatCommand(command, description!, (IChatContext context) async {
      await context.respond(MessageBuilder.empty());

      cmCommandWrapper(mapToMessageEvent(context), onSuccess: onSuccessCallback, onFailure: sendNoAccessMessage);
    }));
  }

  CommandsPlugin _setupDiscordCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!');

    _commands.forEach((command) => commands.addCommand(command));

    return commands;
  }

  // CommandsPlugin setupCommands() {
  // var commands = CommandsPlugin(prefix: (message) => '!');
  //
  // commands.addCommand(
  //     ChatCommand('addcity', 'Add city to receive periodic updates about the weather', (IChatContext context, String city) async {
  //   await context.respond(MessageBuilder.content(city));
  //
  //   cm.userCommand(_mapToMessageEventWithParameters(context, [city]), onSuccess: addWeatherCity, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('removecity', 'Remove city from the watchlist', (IChatContext context, String city) async {
  //   await context.respond(MessageBuilder.content(city));
  //
  //   cm.userCommand(_mapToMessageEventWithParameters(context, [city]), onSuccess: removeWeatherCity, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('watchlist', 'Get weather watchlist', (IChatContext context) async {
  //   await context.respond(MessageBuilder.empty());
  //
  //   cm.userCommand(_mapToGeneralMessageEvent(context), onSuccess: getWeatherWatchlist, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('getweather', 'Get weather for the city', (IChatContext context, String city) async {
  //   await context.respond(MessageBuilder.content(city));
  //
  //   cm.userCommand(_mapToMessageEventWithParameters(context, [city]), onSuccess: getWeatherForCity, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('setnotificationhour', 'Set time for weather notifications', (IChatContext context, String hour) async {
  //   await context.respond(MessageBuilder.content(hour));
  //
  //   cm.moderatorCommand(_mapToMessageEventWithParameters(context, [hour]),
  //       onSuccess: setWeatherNotificationHour, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('write', 'Set time for weather notifications', (IChatContext context, String message) async {
  //   await context.respond(MessageBuilder.content(message));
  //
  //   cm.moderatorCommand(_mapToMessageEventWithParameters(context, [message]), onSuccess: writeToChat, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('updatemessage', 'Send latest updates message to the chat', (IChatContext context) async {
  //   await context.respond(MessageBuilder.empty());
  //
  //   cm.adminCommand(_mapToGeneralMessageEvent(context), onSuccess: postUpdateMessage, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('sendnews', 'Send news to the chat', (IChatContext context) async {
  //   await context.respond(MessageBuilder.empty());
  //
  //   cm.userCommand(_mapToGeneralMessageEvent(context), onSuccess: sendNewsToChat, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands
  //     .addCommand(ChatCommand('sendrealmusic', 'Convert link from YouTube Music to YouTube', (IChatContext context, String link) async {
  //   await context.respond(MessageBuilder.content(link));
  //
  //   cm.userCommand(_mapToMessageEventWithParameters(context, [link]), onSuccess: sendRealMusicToChat, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('increp', 'Increase reputation for the user', (IChatContext context, IMember who) async {
  //   await context.respond(MessageBuilder.content(who.user.getFromCache()?.username ?? 'Unknown user'));
  //
  //   cm.userCommand(_mapToEventWithOtherUserIds(context, [who.user.id.toString()]),
  //       onSuccess: increaseReputation, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('decrep', 'Decrease reputation for the user', (IChatContext context, IMember who) async {
  //   await context.respond(MessageBuilder.content(who.user.getFromCache()?.username ?? 'Unknown user'));
  //
  //   cm.userCommand(_mapToEventWithOtherUserIds(context, [who.user.id.toString()]),
  //       onSuccess: decreaseReputation, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('replist', 'Get reputation list', (IChatContext context) async {
  //   await context.respond(MessageBuilder.empty());
  //
  //   cm.userCommand(_mapToGeneralMessageEvent(context), onSuccess: sendReputationList, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('searchsong', 'Search song on YouTube', (IChatContext context, String query) async {
  //   await context.respond(MessageBuilder.content(query));
  //
  //   cm.userCommand(_mapToMessageEventWithParameters(context, [query]), onSuccess: searchYoutubeTrack, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('ping', 'Check if bot is alive', (IChatContext context) async {
  //   await context.respond(MessageBuilder.empty());
  //
  //   cm.userCommand(_mapToGeneralMessageEvent(context), onSuccess: healthCheck, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('accordion', 'Start a vote if sent content is accordion', (IChatContext context) async {
  //   await context.respond(MessageBuilder.empty());
  //
  //   cm.userCommand(_mapToGeneralMessageEvent(context),
  //       onSuccessCustom: () => _startDiscordAccordionPoll(context), onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(
  //     ChatCommand('ask', 'Ask for advice or anything else from the Conversator', (IChatContext context, String question) async {
  //   await context.respond(MessageBuilder.content(question));
  //
  //   cm.userCommand(_mapToMessageEventWithParameters(context, [question]), onSuccess: askConversator, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('adduser', 'Register new user', (IChatContext context, IMember who) async {
  //   await context.respond(MessageBuilder.content(who.user.getFromCache()?.username ?? 'Unknown user'));
  //
  //   cm.moderatorCommand(_mapToEventWithOtherUserIds(context, [who.user.id.toString()]),
  //       onSuccess: addUser, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('removeuser', 'Remove user from the system', (IChatContext context, IMember who) async {
  //   await context.respond(MessageBuilder.content(who.user.getFromCache()?.username ?? 'Unknown user'));
  //
  //   cm.moderatorCommand(_mapToEventWithOtherUserIds(context, [who.user.id.toString()]),
  //       onSuccess: removeUser, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('initialize', 'Initialize new chat', (IChatContext context) async {
  //   await context.respond(MessageBuilder.empty());
  //
  //   cm.adminCommand(_mapToGeneralMessageEvent(context), onSuccess: removeUser, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('createreputation', 'Create reputation for the user', (IChatContext context, IMember who) async {
  //   await context.respond(MessageBuilder.content(who.user.getFromCache()?.username ?? 'Unknown user'));
  //
  //   cm.adminCommand(_mapToEventWithOtherUserIds(context, [who.user.id.toString()]),
  //       onSuccess: createReputation, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('createweather', 'Activate weather module for the chat', (IChatContext context) async {
  //   await context.respond(MessageBuilder.empty());
  //
  //   cm.adminCommand(_mapToGeneralMessageEvent(context), onSuccess: createWeather, onFailure: sendNoAccessMessage);
  // }));
  //
  // commands.addCommand(ChatCommand('moveall', 'Move all users from one voice channel to another',
  //     (IChatContext context, IChannel fromChannel, IChannel toChannel) async {
  //   await context.respond(MessageBuilder.empty());
  //
  //   cm.moderatorCommand(_mapToGeneralMessageEvent(context),
  //       onSuccessCustom: () => _moveAll(context, fromChannel, toChannel), onFailure: sendNoAccessMessage);
  // }));
  //
  // return commands;
  // }

  @override
  MessageEvent mapToGeneralMessageEvent(IChatContext event) {
    return MessageEvent(
        platform: ChatPlatform.discord,
        chatId: event.guild?.id.toString() ?? '',
        userId: event.user.id.toString(),
        otherUserIds: [],
        isBot: event.user.bot,
        message: '',
        parameters: [],
        rawMessage: event);
  }

  @override
  MessageEvent mapToMessageEventWithParameters(IChatContext event, [List? otherParameters]) {
    return mapToGeneralMessageEvent(event)..parameters.addAll(otherParameters as List<String>);
  }

  @override
  MessageEvent mapToMessageEventWithOtherUserIds(IChatContext event, [List? otherUserIds]) {
    return mapToGeneralMessageEvent(event)..otherUserIds.addAll(otherUserIds as List<String>);
  }

  void _startHeroCheckJob() async {
    // TODO: onlineUsers are returned for a single chat only. Fix this + make this job configurable per chat
    Cron().schedule(Schedule.parse('0 5 * * 6,0'), () async {
      var authorizedChats = await chatManager.getAllChatIds(ChatPlatform.discord);

      await Process.run('${Directory.current.path}/generate-online', []);

      var onlineFile = File('assets/online');
      var onlineUsers = await onlineFile.readAsLines();

      await Future.forEach(authorizedChats, (chatId) async {
        var guild = await bot.httpEndpoints.fetchGuild(Snowflake(chatId));
        var channelId = guild.systemChannel?.id.toString() ?? '';

        if (onlineUsers.isEmpty) {
          return sendMessage(channelId, sm.get('hero.users_at_five.no_users'));
        }

        var heroesMessage = sm.get('hero.users_at_five.list');
        var chatUsers = await userManager.getUsersForChat(chatId);

        onlineUsers.forEach((userId) {
          var onlineUser = chatUsers.firstWhereOrNull((user) => user.id == userId);

          if (onlineUser != null) {
            heroesMessage += onlineUser.name;
            heroesMessage += '\n';
          }
        });

        await sendMessage(channelId, heroesMessage);
      });

      await onlineFile.delete();
    });
  }

  void _moveAll(IContext context, IChannel fromChannel, IChannel toChannel) async {
    await Process.run('${Directory.current.path}/generate-channel-users', []);

    var channelUsersFile = File('assets/channels-users');
    var channelsWithUsersRaw = await channelUsersFile.readAsLines();

    Map<String, dynamic> channelsWithUsers = jsonDecode(channelsWithUsersRaw[0]);
    List usersToMove = channelsWithUsers[fromChannel.toString()];

    var chatId = context.guild?.id.toString() ?? '';

    usersToMove.forEach((user) {
      var builder = MemberBuilder()..channel = Snowflake(toChannel);

      bot.httpEndpoints.editGuildMember(Snowflake(chatId), Snowflake(user), builder: builder);
    });

    await channelUsersFile.delete();
  }

  void _startDiscordAccordionPoll(IChatContext context) {
    sendMessage(context.guild?.id.toString() ?? '', 'Currently not supported');
  }
}
