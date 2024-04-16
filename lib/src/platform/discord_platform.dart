import 'dart:async';

import 'package:collection/collection.dart';
import 'package:nyxx/nyxx.dart' hide Logger, User;
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:uuid/uuid.dart';
import 'package:cron/cron.dart';

import 'package:weather/src/modules/chat/chat.dart';
import 'package:weather/src/core/access.dart';

import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/bot_command.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/modules/user/user.dart';

import 'package:weather/src/platform/platform.dart';

import 'package:weather/src/utils/logger.dart';

const uuid = Uuid();
const emptyCharacter = 'ㅤ';

class DiscordPlatform<T extends ChatContext> implements Platform<T> {
  @override
  late ChatPlatform chatPlatform;
  final String token;
  final String adminId;
  final Chat chat;
  final User user;
  final Access _access;
  final Logger _logger;

  final List<ChatCommand> _commands = [];
  final Map<String, Map<String, bool>> _usersOnlineStatus = {};

  late NyxxGateway bot;

  DiscordPlatform({required this.chatPlatform, required this.token, required this.adminId, required this.chat, required this.user})
      : _access = getIt<Access>(),
        _logger = getIt<Logger>();

  @override
  Future<void> initialize() async {
    _logger.i('No initialize script for Discord');
  }

  @override
  Future<void> postStart() async {
    _setupPlatformSpecificCommands();

    bot = await Nyxx.connectGateway(token, GatewayIntents.all,
        options: GatewayClientOptions(plugins: [_setupDiscordCommands(), logging, cliIntegration, ignoreExceptions]));

    _startHeroCheckJob();
    _watchUsersStatusUpdate();

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
    var formattedParameters = otherParameters?.first?.toString().split(' ');

    return transformPlatformMessageToGeneralMessageEvent(event)..parameters.addAll(formattedParameters ?? []);
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

  void _setupCommandWithOtherUserIds(BotCommand command) {
    _commands.add(ChatCommand(command.command, command.description, (ChatContext context, Member who) async {
      var user = await bot.users.get(who.id);
      var isPremium = user.nitroType.value > 0 ? 'true' : 'false';
      await context.respond(MessageBuilder(content: user.username));

      _access.execute(
          event: transformPlatformMessageToMessageEventWithOtherUserIds(context, [who.id])..parameters.addAll([user.username, isPremium]),
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

  // TODO: move to the module e.g. discord_module to avoid User dependency here. Move all platform specific commands to this module. Do the same for Telegram
  void _startHeroCheckJob() {
    Cron().schedule(Schedule.parse('0 4 * * 6,0'), () async {
      var authorizedChats = await chat.getAllChatIdsForPlatform(chatPlatform);

      await Future.forEach(authorizedChats, (chatId) async {
        var chatOnlineUsers = _usersOnlineStatus[chatId];
        if (chatOnlineUsers == null) {
          _logger.w('Attempt to get online users for empty chat $chatId');

          return null;
        }

        var listOfOnlineUsers = chatOnlineUsers.entries.where((entry) => entry.value == true).map((entry) => entry.key).toList();
        if (listOfOnlineUsers.isEmpty) {
          return sendMessage(chatId, translation: 'hero.users_at_five.no_users');
        }

        var chatUsers = await user.getUsersForChat(chatId);
        var heroesMessage = chat.getText(chatId, 'hero.users_at_five.list');

        listOfOnlineUsers.forEach((userId) {
          var onlineUser = chatUsers.firstWhereOrNull((user) => user.id == userId);

          if (onlineUser != null) {
            heroesMessage += onlineUser.name;
            heroesMessage += '\n';
          }
        });

        await sendMessage(chatId, message: heroesMessage);
      });
    });
  }

  void _watchUsersStatusUpdate() {
    bot.onPresenceUpdate.listen((event) {
      var userId = event.user?.id.toString();
      var guildId = event.guildId?.toString();

      if (userId == null || guildId == null) {
        return;
      }

      if (event.status == UserStatus.online) {
        (_usersOnlineStatus[guildId] ??= {})[userId] = true;
      } else {
        (_usersOnlineStatus[guildId] ??= {})[userId] = false;
      }
    });
  }

  void _moveAll(ChatContext context, Channel fromChannel, Channel toChannel) async {
    context.guild?.voiceStates.entries.toList().forEach((voiceState) {
      if (voiceState.value.channelId == fromChannel.id) {
        context.guild?.members.update(voiceState.value.userId, MemberUpdateBuilder(voiceChannelId: toChannel.id));
      }
    });
  }
}
