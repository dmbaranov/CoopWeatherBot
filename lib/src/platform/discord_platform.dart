import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:uuid/uuid.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/command.dart';
import 'package:weather/src/globals/message_event.dart';

import 'package:weather/src/modules/commands_manager.dart';
import 'package:weather/src/modules/chat_manager.dart';
import 'package:weather/src/modules/youtube.dart';

import 'package:weather/src/platform/platform.dart';

const uuid = Uuid();

class DiscordPlatform<T extends IChatContext> implements Platform<T> {
  final String token;
  final String adminId;
  final ChatManager chatManager;
  final Youtube youtube;

  final List<ChatCommand> _commands = [];

  late INyxxWebsocket bot;

  DiscordPlatform({required this.token, required this.adminId, required this.chatManager, required this.youtube});

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

    print('Discord platform has been started!');
  }

  @override
  Future<IMessage> sendMessage(String chatId, String message) async {
    var guild = await bot.httpEndpoints.fetchGuild(Snowflake(chatId));
    var channelId = guild.systemChannel?.id.toString() ?? '';

    return bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(message));
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
    // TODO: implement setupPlatformSpecificCommands
    print('setupPlatformSpecificCommands');
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
}
