import 'dart:io';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:uuid/uuid.dart';
import 'package:cron/cron.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/command.dart';
import 'package:weather/src/globals/message_event.dart';

import 'package:weather/src/modules/commands_manager.dart';
import 'package:weather/src/modules/chat_manager.dart';
import 'package:weather/src/modules/user_manager.dart';

import 'package:weather/src/platform/platform.dart';

const uuid = Uuid();

class DiscordPlatform<T extends IChatContext> implements Platform<T> {
  final String token;
  final String adminId;
  final ChatManager chatManager;
  final UserManager userManager;

  final List<ChatCommand> _commands = [];

  late INyxxWebsocket bot;

  DiscordPlatform({required this.token, required this.adminId, required this.chatManager, required this.userManager});

  @override
  Future<void> initializePlatform() async {
    bot = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.all);
  }

  @override
  Future<void> postStart() async {
    bot
      ..registerPlugin(Logging())
      ..registerPlugin(CliIntegration())
      ..registerPlugin(IgnoreExceptions())
      ..registerPlugin(_setupDiscordCommands());

    await bot.connect();

    _startHeroCheckJob();

    print('Discord platform has been started!');
  }

  @override
  Future<IMessage> sendMessage(String chatId, {String? message, String? translation}) async {
    var guild = await bot.httpEndpoints.fetchGuild(Snowflake(chatId));
    var channelId = guild.systemChannel?.id.toString() ?? '';

    if (message != null) {
      return bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(message));
    } else if (translation != null) {
      return bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(chatManager.getText(chatId, translation)));
    }

    return bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(chatManager.getText(chatId, 'something_went_wrong')));
  }

  @override
  Future<void> sendNoAccessMessage(MessageEvent event) async {
    await sendMessage(event.chatId, chatManager.getText(event.chatId, 'general.no_access'));
  }

  @override
  Future<void> sendErrorMessage(MessageEvent event) async {
    await sendMessage(event.chatId, chatManager.getText(event.chatId, 'general.something_went_wrong'));
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
  void setupPlatformSpecificCommands(CommandsManager cm) {
    _commands.add(ChatCommand('moveall', 'Move all users from one voice channel to another',
        (IChatContext context, IChannel fromChannel, IChannel toChannel) async {
      await context.respond(MessageBuilder.empty());

      cm.moderatorCommand(transformPlatformMessageToGeneralMessageEvent(context),
          onSuccessCustom: () => _moveAll(context, fromChannel, toChannel), onFailure: sendNoAccessMessage);
    }));
  }

  @override
  MessageEvent transformPlatformMessageToGeneralMessageEvent(IChatContext event) {
    return MessageEvent(
        platform: ChatPlatform.discord,
        // TODO: replace guildId with channelId?
        chatId: event.guild?.id.toString() ?? '',
        userId: event.user.id.toString(),
        otherUserIds: [],
        isBot: event.user.bot,
        parameters: [],
        rawMessage: event);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithParameters(IChatContext event, [List? otherParameters]) {
    return transformPlatformMessageToGeneralMessageEvent(event)
      ..parameters.addAll(otherParameters?.map((param) => param.toString()).toList() ?? []);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithOtherUserIds(IChatContext event, [List? otherUserIds]) {
    return transformPlatformMessageToGeneralMessageEvent(event)
      ..otherUserIds.addAll(otherUserIds?.map((param) => param.toString()).toList() ?? []);
  }

  @override
  MessageEvent transformPlatformMessageToConversatorMessageEvent(IChatContext event, [List<String>? otherParameters]) {
    return transformPlatformMessageToGeneralMessageEvent(event)..parameters.addAll(otherParameters ?? []);
  }

  @override
  Future<bool> getUserPremiumStatus(String chatId, String userId) async {
    var discordUser = await bot.httpEndpoints.fetchGuildMember(Snowflake(chatId), Snowflake(userId));

    return discordUser.boostingSince != null;
  }

  @override
  String getMessageId(message) {
    return (message as IMessage).id.toString();
  }

  CommandsPlugin _setupDiscordCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!');

    _commands.forEach((command) => commands.addCommand(command));

    return commands;
  }

  void _setupSimpleCommand(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context) async {
      await context.respond(MessageBuilder.empty());

      command.wrapper(transformPlatformMessageToGeneralMessageEvent(context),
          onSuccess: command.successCallback, onFailure: sendNoAccessMessage);
    }));
  }

  void _setupCommandWithParameters(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context, String what) async {
      await context.respond(MessageBuilder.content(what));

      command.wrapper(transformPlatformMessageToMessageEventWithParameters(context, [what]), onSuccess: command.successCallback,
          onFailure: () {
        print('no_access_message');
      });
    }));
  }

  void _setupCommandWithOtherUserIds(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context, IMember who) async {
      var user = await who.user.getOrDownload();
      var isPremium = who.boostingSince != null ? 'true' : 'false';
      await context.respond(MessageBuilder.content(user.username));

      command.wrapper(
          transformPlatformMessageToMessageEventWithOtherUserIds(context, [who.user.id.toString()])
            ..parameters.addAll([user.username, isPremium]),
          onSuccess: command.successCallback, onFailure: () {
        print('no_access_message');
      });
    }));
  }

  void _setupCommandForConversator(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context, String what, [String? conversationId]) async {
      await context.respond(MessageBuilder.content(what));

      conversationId ??= uuid.v4();
      var currentMessageId = uuid.v4();

      command.wrapper(transformPlatformMessageToConversatorMessageEvent(context, [conversationId, currentMessageId, what]),
          onSuccess: command.successCallback, onFailure: () {
        print('no_access_message');
      });
    }));
  }

  void _startHeroCheckJob() {
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