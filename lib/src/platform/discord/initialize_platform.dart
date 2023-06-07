import 'package:nyxx/nyxx.dart';

Future<INyxxWebsocket> initializeDiscord(String token) async {
  var bot = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.all);

  // TODO: missing _setupDiscordCommands
  bot
    ..registerPlugin(Logging())
    ..registerPlugin(CliIntegration())
    ..registerPlugin(IgnoreExceptions());

  // TODO: move this to post_start?
  await bot.connect();

  return bot;
}
