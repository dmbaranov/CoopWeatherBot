import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:cron/cron.dart';
import 'package:uuid/uuid.dart';

import 'package:weather/src/bot/bot.dart';
import 'package:weather/src/modules/chat_manager.dart';
import 'package:weather/src/modules/commands_manager.dart';

const uuid = Uuid();

class DiscordBot extends Bot<IChatContext, IMessage> {
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

    setupCommands();
    setupPlatformSpecificCommands();

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
  Future<IMessage> sendMessage(String chatId, String message) async {
    var guild = await bot.httpEndpoints.fetchGuild(Snowflake(chatId));
    var channelId = guild.systemChannel?.id.toString() ?? '';

    return bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(message));
  }

  @override
  void setupCommand(Command command) {
    if (command.withParameters) {
      _setupCommandWithParameters(command);
    } else if (command.withOtherUserIds) {
      _setupCommandWithOtherUserIds(command);
    } else if (command.conversatorCommand) {
      _setupCommandForConversator(command);
    } else {
      _setupSimpleCommand(command);
    }
  }

  @override
  void setupPlatformSpecificCommands() {
    _commands.add(ChatCommand('moveall', 'Move all users from one voice channel to another',
        (IChatContext context, IChannel fromChannel, IChannel toChannel) async {
      await context.respond(MessageBuilder.empty());

      cm.moderatorCommand(mapToGeneralMessageEvent(context),
          onSuccessCustom: () => _moveAll(context, fromChannel, toChannel), onFailure: sendNoAccessMessage);
    }));
  }

  @override
  MessageEvent mapToGeneralMessageEvent(IChatContext event) {
    return MessageEvent(
        platform: ChatPlatform.discord,
        chatId: event.guild?.id.toString() ?? '',
        userId: event.user.id.toString(),
        otherUserIds: [],
        isBot: event.user.bot,
        parameters: [],
        rawMessage: event);
  }

  @override
  MessageEvent mapToMessageEventWithParameters(IChatContext event, [List? otherParameters]) {
    return mapToGeneralMessageEvent(event)..parameters.addAll(otherParameters?.map((param) => param.toString()).toList() ?? []);
  }

  @override
  MessageEvent mapToMessageEventWithOtherUserIds(IChatContext event, [List? otherUserIds]) {
    return mapToGeneralMessageEvent(event)..otherUserIds.addAll(otherUserIds?.map((param) => param.toString()).toList() ?? []);
  }

  @override
  MessageEvent mapToConversatorMessageEvent(IChatContext event, [List<String> otherParameters = const []]) {
    return mapToGeneralMessageEvent(event)..parameters.addAll(otherParameters);
  }

  @override
  String getMessageId(IMessage message) {
    return message.id.toString();
  }

  CommandsPlugin _setupDiscordCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!');

    _commands.forEach((command) => commands.addCommand(command));

    return commands;
  }

  void _setupSimpleCommand(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context) async {
      await context.respond(MessageBuilder.empty());

      command.wrapper(mapToGeneralMessageEvent(context), onSuccess: command.successCallback, onFailure: sendNoAccessMessage);
    }));
  }

  void _setupCommandWithParameters(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context, String what) async {
      await context.respond(MessageBuilder.content(what));

      command.wrapper(mapToMessageEventWithParameters(context, [what]), onSuccess: command.successCallback, onFailure: sendNoAccessMessage);
    }));
  }

  void _setupCommandWithOtherUserIds(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context, IMember who) async {
      var user = await who.user.getOrDownload();
      await context.respond(MessageBuilder.content(user.username));

      command.wrapper(mapToMessageEventWithOtherUserIds(context, [who.user.id.toString()]),
          onSuccess: command.successCallback, onFailure: sendNoAccessMessage);
    }));
  }

  void _setupCommandForConversator(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context, String what, [String? conversationId]) async {
      await context.respond(MessageBuilder.content(what));

      conversationId ??= uuid.v4();
      var currentMessageId = uuid.v4();

      command.wrapper(mapToConversatorMessageEvent(context, [conversationId, currentMessageId, what]),
          onSuccess: command.successCallback, onFailure: sendNoAccessMessage);
    }));
  }

  void _startHeroCheckJob() async {
    // TODO: onlineUsers are returned for a single chat only. Fix this + make this job configurable per chat
    Cron().schedule(Schedule.parse('0 5 * * 6,0'), () async {
      var authorizedChats = await chatManager.getAllChatIdsForPlatform(ChatPlatform.discord);

      await Process.run('${Directory.current.path}/generate-online', []);

      var onlineFile = File('assets/online');
      var onlineUsers = await onlineFile.readAsLines();

      await Future.forEach(authorizedChats, (chatId) async {
        if (onlineUsers.isEmpty) {
          return sendMessage(chatId, chatManager.getText(chatId, 'hero.users_at_five.no_users'));
        }

        var heroesMessage = chatManager.getText(chatId, 'hero.users_at_five.list');
        var chatUsers = await userManager.getUsersForChat(chatId);

        onlineUsers.forEach((userId) {
          var onlineUser = chatUsers.firstWhereOrNull((user) => user.id == userId);

          if (onlineUser != null) {
            heroesMessage += onlineUser.name;
            heroesMessage += '\n';
          }
        });

        await sendMessage(chatId, heroesMessage);
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
}
