import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import 'package:weather/src/bot/bot.dart';
import 'package:weather/src/modules/commands_manager.dart';

class DiscordBot extends Bot {
  late INyxxWebsocket bot;

  DiscordBot(
      {required super.botToken,
      required super.repoUrl,
      required super.openweatherKey,
      required super.conversatorKey,
      required super.dbConnection,
      required super.youtubeKey});

  @override
  Future<void> startBot() async {
    bot = NyxxFactory.createNyxxWebsocket(botToken, GatewayIntents.all);

    bot
      ..registerPlugin(Logging())
      ..registerPlugin(CliIntegration())
      ..registerPlugin(IgnoreExceptions())
      ..registerPlugin(setupCommands());
  }

  MessageEvent mapToMessageEvent(IChatContext context) {
    return MessageEvent(
        chatId: context.guild?.id.toString() ?? '', userId: context.user.id.toString(), isBot: context.user.bot, message: 'TODO');
  }

  MessageEvent mapToMessageEventWithOneUser(IChatContext context, IMember anotherUser) {
    return MessageEvent(
        chatId: context.guild?.id.toString() ?? '',
        userId: context.user.id.toString(),
        selectedUserId: anotherUser.id.toString(),
        isBot: context.user.bot,
        message: 'TODO');
  }

  @override
  Future<void> sendMessage(String chatId, String message) async {
    var guild = await bot.httpEndpoints.fetchGuild(Snowflake(chatId));
    var channelId = guild.systemChannel?.id.toString() ?? '';

    await bot.httpEndpoints.sendMessage(Snowflake(channelId), MessageBuilder.content(message));
  }

  @override
  CommandsPlugin setupCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!');

    commands.addCommand(ChatCommand('addcity', 'Add city to receive periodic updates about the weather',
        (IChatContext context) => cm.userCommand(mapToMessageEvent(context), onSuccess: addCity, onFailure: sendNoAccessMessage)));

    commands.addCommand(ChatCommand(
        'moveall',
        'Increase reputation for the user',
        (IChatContext context, IChannel from, IChannel to) =>
            cm.userCommand(mapToMessageEvent(context), onSuccess: () => moveAll(context, from, to), onFailure: sendNoAccessMessage)));

    return commands;
  }

  void moveAll(IContext context, IChannel from, IChannel to) {
    print('moving...');
  }
}
