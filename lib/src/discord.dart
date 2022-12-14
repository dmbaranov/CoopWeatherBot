import 'dart:async';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';

import 'modules/swearwords_manager.dart';
import 'modules/reputation.dart';

import 'utils.dart';

class DiscordBot {
  final String token;
  final String guildId;
  final String adminId;
  late INyxxWebsocket bot;
  late List<IUser> users;
  late SwearwordsManager sm;
  late Reputation reputation;

  DiscordBot({required this.token, required this.adminId, required this.guildId});

  void startBot() async {
    bot = NyxxFactory.createNyxxWebsocket(token, GatewayIntents.all);

    bot
      ..registerPlugin(Logging())
      ..registerPlugin(CliIntegration())
      ..registerPlugin(IgnoreExceptions())
      ..registerPlugin(_setupCommands());

    await bot.connect();
    await _updateUsersList();

    sm = SwearwordsManager();
    await sm.initSwearwords();

    reputation = Reputation(sm: sm);
    await reputation.initReputation();
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

    commands
      ..addCommand(_getIncreaseReputationCommand())
      ..addCommand(_getDecreaseReputationCommand())
      ..addCommand(_getReputationListCommand())
      ..addCommand(_getGenerateReputationUsersCommand());

    return commands;
  }

  Future<void> _updateUsersList() async {
    var guild = await bot.fetchGuild(Snowflake(guildId));
    var userIds = [];
    var usersStream = guild.fetchMembers(limit: 999).listen((userId) => userIds.add(userId));

    await Future.wait([usersStream.asFuture()]);

    users = await Future.wait(userIds.map((userId) async => await bot.fetchUser(Snowflake(userId))));
    users = users.where((user) => user.bot == false).toList();
  }

  ChatCommand _getIncreaseReputationCommand() {
    return ChatCommand('increp', 'Increase reputation for the user', (IChatContext context, String who) async {
      await context.respond(MessageBuilder.content(sm.get('starting_reputation_change')));
      var from = context.user.id.toString();
      var to = who.substring(2, who.length - 1);

      var result = await reputation.updateReputation(from, to, 'increase');

      await context.respond(MessageBuilder.content(result));
    });
  }

  ChatCommand _getDecreaseReputationCommand() {
    return ChatCommand('decrep', 'Increase reputation for the user', (IChatContext context, String who) async {
      await context.respond(MessageBuilder.content(sm.get('starting_reputation_change')));
      var from = context.user.id.toString();
      var to = who.substring(2, who.length - 1);

      var result = await reputation.updateReputation(from, to, 'decrease');

      await context.respond(MessageBuilder.content(result));
    });
  }

  ChatCommand _getReputationListCommand() {
    return ChatCommand('replist', 'Get current reputation', (IChatContext context) async {
      await context.respond(MessageBuilder.content(sm.get('starting_reputation_list_generation')));

      var reputationMessage = reputation.getReputationMessage();

      await context.respond(MessageBuilder.content(reputationMessage));
    });
  }

  ChatCommand _getGenerateReputationUsersCommand() {
    return ChatCommand('setrepusers', 'Update reputation users', (IChatContext context) async {
      await context.respond(MessageBuilder.content(sm.get('starting_reputation_users_update')));

      if (context.user.id.toString() != adminId) {
        return context.respond(MessageBuilder.content(sm.get('you_are_not_an_admin')));
      }

      var reputationUsers = users
          .map((rawUser) => ReputationUser.fromJson({'userId': rawUser.id.toString(), 'reputation': 0, 'fullName': rawUser.username}))
          .toList();

      await reputation.setUsers(reputationUsers);
      await context.respond(MessageBuilder.content(sm.get('finished_reputation_users_update')));
    });
  }
}
