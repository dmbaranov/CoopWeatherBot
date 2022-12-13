import 'dart:async';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'utils.dart';

class DiscordBot {
  final String token;
  final String guildId;
  late INyxxWebsocket bot;
  late List<IUser> users;

  DiscordBot({required this.token, required this.guildId});

  void startBot() async {
    bot = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.all);

    bot
      ..registerPlugin(Logging())
      ..registerPlugin(CliIntegration())
      ..registerPlugin(IgnoreExceptions())
      ..registerPlugin(_setupCommands());

    await bot.connect();
    await _updateUsersList();
  }

  void startAwakeUsersPolling() async {
    var skip = false;

    Timer.periodic(Duration(seconds: 30), (_) async {
      if (skip) return;

      var day = DateTime.now().weekday;
      var hour = DateTime.now().hour;

      if (hour != 5) return;

      skip = true;

      if (day == 5 || day == 6) {
        print('handle online after 5 on Friday or Saturday');
      } else {
        print('handling online after 5 on any other day');
      }

      await sleep(Duration(hours: 23));
      skip = false;
    });
  }

  // TODO: add command to move all from one channel to another
  CommandsPlugin _setupCommands() {
    var commands = CommandsPlugin(prefix: (message) => '!', guild: Snowflake(guildId));
    var increaseRep = ChatCommand('prep', 'Increase reputation for the user', (IChatContext context, String who) {});

    commands.addCommand(increaseRep);

    return commands;
  }

  Future<void> _updateUsersList() async {
    var guild = await bot.fetchGuild(Snowflake(guildId));
    var userIds = [];
    var usersStream = guild.fetchMembers(limit: 999).listen((userId) => userIds.add(userId));

    await Future.wait([usersStream.asFuture()]);

    users = await Future.wait(userIds.map((userId) async => await bot.fetchUser(Snowflake(userId))));
  }
}
