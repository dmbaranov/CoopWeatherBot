import 'dart:async';

import 'package:nyxx/nyxx.dart' hide Logger, User, Poll;
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:uuid/uuid.dart';
import 'package:weather/src/core/swearwords.dart';

import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/config.dart';
import 'package:weather/src/core/access.dart';

import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/globals/poll.dart';
import 'package:weather/src/modules/modules_mediator.dart';
import 'package:weather/src/utils/logger.dart';
import 'discord_module.dart';

const uuid = Uuid();
const emptyCharacter = 'ㅤ';

class DiscordPlatform<T extends ChatContext> implements Platform<T> {
  @override
  late final ChatPlatform chatPlatform;
  final ModulesMediator modulesMediator;
  final Config _config;
  final Access _access;
  final Logger _logger;
  final Swearwords _sw;
  late final DiscordModule _discordModule;

  final List<ChatCommand> _commands = [];

  late NyxxGateway bot;

  DiscordPlatform({required this.chatPlatform, required this.modulesMediator})
      : _config = getIt<Config>(),
        _access = getIt<Access>(),
        _logger = getIt<Logger>(),
        _sw = getIt<Swearwords>();

  @override
  void initialize() async {
    _logger.i('No initialize script for Discord');
  }

  @override
  Future<void> postStart() async {
    _setupPlatformSpecificCommands();

    bot = await Nyxx.connectGateway(_config.token, GatewayIntents.all,
        options: GatewayClientOptions(plugins: [_setupDiscordCommands(), logging, cliIntegration, ignoreExceptions]));

    _discordModule = DiscordModule(bot: bot, platform: this, modulesMediator: modulesMediator)..initialize();

    _logger.i('Discord platform has been started!');
  }

  @override
  Future<Message> sendMessage(String chatId, {String? message, String? translation}) async {
    var guild = await bot.guilds.get(Snowflake(int.parse(chatId)));
    var channelId = guild.systemChannel?.id ?? Snowflake.zero;
    var channel = await bot.channels.get(channelId) as TextChannel;

    if (message != null) {
      return channel.sendMessage(MessageBuilder(content: message));
    } else if (translation != null) {
      return channel.sendMessage(MessageBuilder(content: _sw.getText(chatId, translation)));
    }

    return channel.sendMessage(MessageBuilder(content: _sw.getText(chatId, 'something_went_wrong')));
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
    } else if (command.withOtherUser) {
      _setupCommandWithOtherUser(command);
    } else if (command.conversatorCommand) {
      _setupCommandForConversator(command);
    } else {
      _setupSimpleCommand(command);
    }
  }

  @override
  MessageEvent transformPlatformMessageToGeneralMessageEvent(ChatContext event) {
    return MessageEvent(
        chatId: event.guild?.id.toString() ?? '',
        userId: event.user.id.toString(),
        isBot: event.user.isBot,
        parameters: [],
        rawMessage: event);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithParameters(ChatContext event, [List? otherParameters]) {
    var formattedParameters = otherParameters?.first?.toString().split(' ');

    return transformPlatformMessageToGeneralMessageEvent(event)..parameters.addAll(formattedParameters ?? []);
  }

  @override
  MessageEvent transformPlatformMessageToMessageEventWithOtherUser(ChatContext event,
      [({String id, String name, bool isPremium})? otherUser]) {
    return transformPlatformMessageToGeneralMessageEvent(event)..otherUser = otherUser;
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
  concludePoll(String chatId, Poll poll) {
    throw 'Not implemented';
  }

  void _setupPlatformSpecificCommands() {
    _commands.add(ChatCommand('moveall', '[M] Move all users from one voice channel to another',
        (ChatContext context, GuildVoiceChannel fromChannel, GuildVoiceChannel toChannel) async {
      await context.respond(MessageBuilder(content: '${fromChannel.name} -> ${toChannel.name}'));

      _access.execute(
          event: transformPlatformMessageToGeneralMessageEvent(context),
          command: 'moveall',
          accessLevel: AccessLevel.moderator,
          onSuccess: (_) => _discordModule.moveAll(context, fromChannel, toChannel),
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

      _access.execute(
          event: transformPlatformMessageToGeneralMessageEvent(context),
          command: command.command,
          accessLevel: command.accessLevel,
          onSuccess: command.onSuccess,
          onFailure: sendNoAccessMessage);
    }));
  }

  void _setupCommandWithParameters(BotCommand command) {
    _commands.add(ChatCommand(command.command, command.description, (ChatContext context, String what) async {
      await context.respond(MessageBuilder(content: what));

      _access.execute(
          event: transformPlatformMessageToMessageEventWithParameters(context, [what]),
          command: command.command,
          accessLevel: command.accessLevel,
          onSuccess: command.onSuccess,
          onFailure: sendNoAccessMessage);
    }));
  }

  void _setupCommandWithOtherUser(BotCommand command) {
    _commands.add(ChatCommand(command.command, command.description, (ChatContext context, Member who) async {
      var user = await bot.users.get(who.id);
      var isPremium = user.nitroType.value > 0;
      await context.respond(MessageBuilder(content: user.username));

      _access.execute(
          event: transformPlatformMessageToMessageEventWithOtherUser(
              context, (id: who.id.toString(), name: user.username, isPremium: isPremium)),
          command: command.command,
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

      _access.execute(
          event: transformPlatformMessageToConversatorMessageEvent(context, [conversationId, currentMessageId, what]),
          command: command.command,
          accessLevel: command.accessLevel,
          onSuccess: command.onSuccess,
          onFailure: sendNoAccessMessage);
    }));
  }
}
