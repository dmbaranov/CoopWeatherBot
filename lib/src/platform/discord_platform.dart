import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:uuid/uuid.dart';
import 'package:cron/cron.dart';

import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/user.dart' as weather;
import 'package:weather/src/core/event_bus.dart';
import 'package:weather/src/core/access.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/access_level.dart';

import 'package:weather/src/platform/platform.dart';

const uuid = Uuid();
const emptyCharacter = 'ㅤ';

class DiscordPlatform<T extends ChatContext> implements Platform<T> {
  @override
  late ChatPlatform chatPlatform;
  final String token;
  final String adminId;
  final EventBus eventBus;
  final Access access;
  final Chat chat;
  final weather.User user;

  final List<ChatCommand> _commands = [];

  late NyxxGateway bot;

  DiscordPlatform(
      {required this.chatPlatform,
      required this.token,
      required this.adminId,
      required this.eventBus,
      required this.access,
      required this.chat,
      required this.user});

  @override
  Future<void> initialize() async {}

  @override
  Future<void> postStart() async {
    _setupPlatformSpecificCommands();

    bot = await Nyxx.connectGateway(token, GatewayIntents.all,
        options: GatewayClientOptions(plugins: [_setupDiscordCommands(), logging, cliIntegration, ignoreExceptions]));

    _startHeroCheckJob();

    print('Discord platform has been started!');
  }

  @override
  Future<Message> sendMessage(String chatId, {String? message, String? translation}) async {
    var guild = await bot.guilds.fetch(Snowflake(int.parse(chatId)));
    var channelId = guild.systemChannel?.id ?? Snowflake.zero;
    var channel = await bot.channels.get(channelId) as TextChannel;

    if (message != null) {
      return channel.sendMessage(MessageBuilder(content: message));
    } else if (translation != null) {
      return channel.sendMessage(MessageBuilder(content: chat.getText(chatId, translation)));
    }

    return channel.sendMessage(MessageBuilder(content: chat.getText(chatId, 'something_went_wrong')));
  }

  @override
  Future<void> sendNoAccessMessage(MessageEvent event) async {
    await sendMessage(event.chatId, translation: 'general.no_access');
  }

  @override
  Future<void> sendErrorMessage(MessageEvent event) async {
    await sendMessage(event.chatId, translation: 'general.something_went_wrong');
  }

  @override
  void setupCommand(BotCommand command) {
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
  MessageEvent transformPlatformMessageToGeneralMessageEvent(ChatContext event) {
    return MessageEvent(
        platform: chatPlatform,
        chatId: event.guild?.id.toString() ?? '',
        userId: event.user.id.toString(),
        otherUserIds: [],
        isBot: event.user.isBot,
        parameters: [],
        rawMessage: event);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithParameters(ChatContext event, [List? otherParameters]) {
    return transformPlatformMessageToGeneralMessageEvent(event)
      ..parameters.addAll(otherParameters?.map((param) => param.toString()).toList() ?? []);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithOtherUserIds(ChatContext event, [List? otherUserIds]) {
    return transformPlatformMessageToGeneralMessageEvent(event)
      ..otherUserIds.addAll(otherUserIds?.map((param) => param.toString()).toList() ?? []);
  }

  @override
  MessageEvent transformPlatformMessageToConversatorMessageEvent(ChatContext event, [List<String>? otherParameters]) {
    return transformPlatformMessageToGeneralMessageEvent(event)..parameters.addAll(otherParameters ?? []);
  }

  @override
  Future<bool> getUserPremiumStatus(String chatId, String userId) async {
    var discordUser = await bot.users.fetch(Snowflake(int.parse(userId)));

    return discordUser.nitroType.value > 0;
  }

  @override
  String getMessageId(dynamic message) {
    return message.id.toString();
  }

  @override
  startAccordionPoll(String chatId, List<String> pollOptions, int pollTime) {
    throw "Not implemented";
  }

  void _setupPlatformSpecificCommands() {
    _commands.add(ChatCommand('moveall', 'Move all users from one voice channel to another',
        (ChatContext context, Channel fromChannel, Channel toChannel) async {
      await context.respond(MessageBuilder(content: emptyCharacter));

      access.execute(
          event: transformPlatformMessageToGeneralMessageEvent(context),
          accessLevel: AccessLevel.moderator,
          onSuccess: (_) => _moveAll(context, fromChannel, toChannel),
          onFailure: sendNoAccessMessage);
    }));
  }

  CommandsPlugin _setupDiscordCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!', options: CommandsOptions(logErrors: true));

    _commands.forEach((command) => commands.addCommand(command));

    return commands;
  }

  void _setupSimpleCommand(BotCommand command) {
    _commands.add(ChatCommand(command.command, command.description, (ChatContext context) async {
      await context.respond(MessageBuilder(content: emptyCharacter));

      access.execute(
          event: transformPlatformMessageToGeneralMessageEvent(context),
          accessLevel: command.accessLevel,
          onSuccess: command.onSuccess,
          onFailure: sendNoAccessMessage);
    }));
  }

  void _setupCommandWithParameters(BotCommand command) {
    _commands.add(ChatCommand(command.command, command.description, (ChatContext context, String what) async {
      await context.respond(MessageBuilder(content: what));

      access.execute(
          event: transformPlatformMessageToMessageEventWithParameters(context, [what]),
          accessLevel: command.accessLevel,
          onSuccess: command.onSuccess,
          onFailure: sendNoAccessMessage);
    }));
  }

  void _setupCommandWithOtherUserIds(BotCommand command) {
    _commands.add(ChatCommand(command.command, command.description, (ChatContext context, Member who) async {
      var user = await bot.users.get(who.id);
      var isPremium = user.nitroType.value > 0 ? 'true' : 'false';
      await context.respond(MessageBuilder(content: user.username));

      access.execute(
          event: transformPlatformMessageToMessageEventWithOtherUserIds(context, [who.id])..parameters.addAll([user.username, isPremium]),
          accessLevel: command.accessLevel,
          onSuccess: command.onSuccess,
          onFailure: sendNoAccessMessage);
    }));
  }

  void _setupCommandForConversator(BotCommand command) {
    _commands.add(ChatCommand(command.command, command.description, (ChatContext context, String what, [String? conversationId]) async {
      await context.respond(MessageBuilder(content: what));

      conversationId ??= uuid.v4();
      var currentMessageId = uuid.v4();

      access.execute(
          event: transformPlatformMessageToConversatorMessageEvent(context, [conversationId, currentMessageId, what]),
          accessLevel: command.accessLevel,
          onSuccess: command.onSuccess,
          onFailure: sendNoAccessMessage);
    }));
  }

  void _startHeroCheckJob() {
    // TODO: onlineUsers are returned for a single chat only. Fix this + make this job configurable per chat
    Cron().schedule(Schedule.parse('0 4 * * 6,0'), () async {
      var authorizedChats = await chat.getAllChatIdsForPlatform(chatPlatform);

      await Process.run('${Directory.current.path}/generate-online', []);

      var onlineFile = File('assets/online');
      var onlineUsers = await onlineFile.readAsLines();

      await Future.forEach(authorizedChats, (chatId) async {
        if (onlineUsers.isEmpty) {
          return sendMessage(chatId, translation: 'hero.users_at_five.no_users');
        }

        var heroesMessage = chat.getText(chatId, 'hero.users_at_five.list');
        var chatUsers = await user.getUsersForChat(chatId);

        onlineUsers.forEach((userId) {
          var onlineUser = chatUsers.firstWhereOrNull((user) => user.id == userId);

          if (onlineUser != null) {
            heroesMessage += onlineUser.name;
            heroesMessage += '\n';
          }
        });

        await sendMessage(chatId, message: heroesMessage);
      });

      await onlineFile.delete();
    });
  }

  void _moveAll(ChatContext context, Channel fromChannel, Channel toChannel) async {
    await Process.run('${Directory.current.path}/generate-channel-users', []);

    var channelUsersFile = File('assets/channels-users');
    var channelsWithUsersRaw = await channelUsersFile.readAsLines();

    Map<String, dynamic> channelsWithUsers = jsonDecode(channelsWithUsersRaw[0]);
    List usersToMove = channelsWithUsers[fromChannel.id.toString()];

    var chatId = context.guild?.id.toString() ?? '';

    List<User> discordUsers = [];

    // https://github.com/nyxx-discord/nyxx/blob/b89952b2069b72e38914a1fc7404d6ad2b4519fd/lib/src/internal/http_endpoints.dart#L908
    // https://github.com/nyxx-discord/nyxx/blob/b89952b2069b72e38914a1fc7404d6ad2b4519fd/lib/src/utils/builders/member_builder.dart#L5
    var guild = await bot.guilds.fetch(Snowflake('guildId'));

    await guild.updateVoiceState(Snowflake('userId'), VoiceStateUpdateBuilder(channelId: Snowflake('new channel id')));

    await Future.forEach(usersToMove, (userId) async => discordUsers.add(await bot.users.get(Snowflake(int.parse(userId)))));

    discordUsers.forEach((user) {
      var builder = GatewayVoiceStateBuilder(channelId: toChannel.id, isMuted: false, isDeafened: false);

      // guil
      // user.manager.update(builder);
    });

    // usersToMove.forEach((user) {
    //   var builder = GatewayVoiceStateBuilder(channelId: toChannel.id, isMuted: false, isDeafened: false);
    //
    //   // var builder = MemberBuilder()..channel = Snowflake(toChannel);
    //   //
    //   // bot.httpEndpoints.editGuildMember(Snowflake(chatId), Snowflake(user), builder: builder);
    // });
    //
    // await channelUsersFile.delete();
  }
}
