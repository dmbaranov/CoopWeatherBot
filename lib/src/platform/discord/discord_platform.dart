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
  final String token;
  final List<ChatCommand> _commands = [];

  late INyxxWebsocket bot;

  DiscordPlatform({required this.token});

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
  Future<void> sendMessage(String chatId, String message) async {
    var guild = await bot.httpEndpoints.fetchGuild(Snowflake(chatId));
    var channelId = guild.systemChannel?.id.toString() ?? '';

    // TODO: should return IMessage
    bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(message));
  }

  @override
  void setupCommand(Command command) {
    _commands.add(ChatCommand(command.command, command.description, (IChatContext context) async {
      await context.respond(MessageBuilder.content('Test'));

      command.wrapper(transformPlatformMessageToGeneralMessageEvent(context), onSuccess: command.successCallback, onFailure: () {
        print('no_access_message');
      });
    }));
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

  CommandsPlugin _setupDiscordCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!');

    _commands.forEach((command) => commands.addCommand(command));

    return commands;
  }
}
