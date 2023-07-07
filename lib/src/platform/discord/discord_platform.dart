import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:uuid/uuid.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/command.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/modules/commands_manager.dart';

import 'package:weather/src/platform/platform.dart';

const uuid = Uuid();

class DiscordPlatform<T extends IChatContext> implements Platform<T> {
  final ChatPlatform chatPlatform = ChatPlatform.discord;
  final String token;
  final List<ChatCommand> _commands = [];

  late INyxxWebsocket bot;

  DiscordPlatform({required this.token});

  @override
  Future<void> initializePlatform() async {
    bot = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.all);

    bot
      ..registerPlugin(Logging())
      ..registerPlugin(CliIntegration())
      ..registerPlugin(IgnoreExceptions());
  }

  @override
  void setupPlatformSpecificCommands(CommandsManager cm) {
    print('setup Discord platform specific commands');
  }

  @override
  Future<void> postStart() async {
    bot.registerPlugin(_setupDiscordCommands());

    await bot.connect();

    print('Discord platform has been started');
  }

  @override
  MessageEvent transformPlatformMessageToGeneralMessageEvent(IChatContext event) {
    return MessageEvent(
        platform: ChatPlatform.discord,
        chatId: event.channel.id.toString(),
        userId: event.user.id.toString(),
        isBot: event.user.bot,
        otherUserIds: [],
        parameters: [],
        rawMessage: event);
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
  Future<void> sendMessage(String chatId, String message) async {
    var guild = await bot.httpEndpoints.fetchGuild(Snowflake(chatId));
    var channelId = guild.systemChannel?.id.toString() ?? '';

    // TODO: should be returned
    bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(message));
  }

  @override
  void _setupCommandWithParameters(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context, String what) async {
      await context.respond(MessageBuilder.content(what));

      command.wrapper(transformPlatformMessageToGeneralMessageEvent(context), onSuccess: command.successCallback, onFailure: () {
        print('no_access_message');
      });
    }));
  }

  CommandsPlugin _setupDiscordCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!');

    _commands.forEach((command) => commands.addCommand(command));

    return commands;
  }

  void _setupCommandWithOtherUserIds(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context, IMember who) async {
      var user = await who.user.getOrDownload();
      var isPremium = who.boostingSince != null ? 'true' : 'false';
      await context.respond(MessageBuilder.content(user.username));

      // TODO: make local _methods for custom mappers? Don't modify shared method?
      // var messageEvent = mapDiscordEventToGeneralMessageEvent(context, [who.user.id.toString()])
      var messageEvent = transformPlatformMessageToGeneralMessageEvent(context)..parameters.addAll([user.username, isPremium]);

      command.wrapper(messageEvent, onSuccess: command.successCallback, onFailure: () {
        print('no_access_message');
      });
    }));
  }

  void _setupCommandForConversator(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context, String what, [String? conversationId]) async {
      await context.respond(MessageBuilder.content(what));

      conversationId ??= uuid.v4();
      var currentMessageId = uuid.v4();

      // command.wrapper(mapDiscordEventToGeneralMessageEvent(context, [conversationId, currentMessageId, what]),
      command.wrapper(transformPlatformMessageToGeneralMessageEvent(context), onSuccess: command.successCallback, onFailure: () {
        print('no_access_message');
      });
    }));
  }

  void _setupSimpleCommand(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context) async {
      await context.respond(MessageBuilder.empty());

      // command.wrapper(transformPlatformMessageToGeneralMessageEvent(context, [what]), onSuccess: command.successCallback, onFailure: () {
      command.wrapper(transformPlatformMessageToGeneralMessageEvent(context), onSuccess: command.successCallback, onFailure: () {
        print('no_access_message');
      });
    }));
  }
}
