import 'package:collection/collection.dart';
import 'package:cron/cron.dart';
import 'package:nyxx/nyxx.dart' hide Logger, User;
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:weather/src/core/repositories/hero_stats_repository.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/modules/chat/chat.dart';
import 'package:weather/src/modules/user/user.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/modules/modules_mediator.dart';
import 'package:weather/src/utils/logger.dart';

class DiscordModule {
  final NyxxGateway bot;
  final Platform platform;
  final ModulesMediator modulesMediator;
  final HeroStatsRepository _heroStatsDb;
  final Logger _logger;
  final Swearwords _sw;
  final Map<String, Map<String, bool>> _usersOnlineStatus = {};

  DiscordModule({required this.bot, required this.platform, required this.modulesMediator})
      : _heroStatsDb = getIt<HeroStatsRepository>(),
        _logger = getIt<Logger>(),
        _sw = getIt<Swearwords>();

  void initialize() {
    _watchUsersStatusUpdate();
    _startHeroCheckJob();
  }

  void moveAll(ChatContext context, GuildVoiceChannel fromChannel, GuildVoiceChannel toChannel) {
    context.guild?.voiceStates.entries.toList().forEach((voiceState) {
      if (voiceState.value.channelId == fromChannel.id) {
        context.guild?.members.update(voiceState.value.userId, MemberUpdateBuilder(voiceChannelId: toChannel.id));
      }
    });
  }

  void _watchUsersStatusUpdate() {
    bot.onPresenceUpdate.listen((event) {
      var userId = event.user?.id.toString();
      var guildId = event.guildId?.toString();

      if (userId == null || guildId == null) {
        return;
      }

      if (event.status == UserStatus.online || event.status == UserStatus.dnd) {
        (_usersOnlineStatus[guildId] ??= {})[userId] = true;
      } else {
        (_usersOnlineStatus[guildId] ??= {})[userId] = false;
      }
    });
  }

  void _startHeroCheckJob() {
    const hour = 3;

    Cron().schedule(Schedule.parse('0 $hour * * 6,0'), () async {
      var authorizedChats = await modulesMediator.get<Chat>().getAllChatIdsForPlatform(ChatPlatform.discord);

      await Future.forEach(authorizedChats, (chatId) async {
        var chatOnlineUsers = _usersOnlineStatus[chatId];
        if (chatOnlineUsers == null) {
          _logger.w('Attempt to get online users for empty chat $chatId');

          return null;
        }

        var listOfOnlineUsers = chatOnlineUsers.entries.where((entry) => entry.value == true).map((entry) => entry.key).toList();
        if (listOfOnlineUsers.isEmpty) {
          var noUsersMessage = _sw.getText(chatId, 'hero.active_users.no_users', {'hour': hour.toString()});

          return platform.sendMessage(chatId, message: noUsersMessage);
        }

        var now = DateTime.now();
        var timestamp = DateTime(now.year, now.month, now.day, hour).toString();
        var chatUsers = await modulesMediator.get<User>().getUsersForChat(chatId);
        var chatUserStats = await _heroStatsDb.getChatHeroStats(chatId);
        var heroesMessage = _sw.getText(chatId, 'hero.active_users.list', {'hour': hour.toString()});
        var heroesStatsMessage = _sw.getText(chatId, 'hero.active_users.stats', {'hour': hour.toString()});

        await Future.forEach(listOfOnlineUsers, (userId) async {
          var onlineUser = chatUsers.firstWhereOrNull((user) => user.id == userId);

          if (onlineUser != null) {
            await _heroStatsDb.createHeroRecord(chatId, onlineUser.id, timestamp);

            heroesMessage += onlineUser.name;
            heroesMessage += '\n';
          }
        });

        chatUserStats.forEach((userStats) {
          var userData = chatUsers.firstWhereOrNull((user) => user.id == userStats.$1);

          if (userData != null) {
            heroesStatsMessage += _sw.getText(
                chatId, 'hero.active_users.hero_stats', {'hero': userData.name, 'hour': hour.toString(), 'count': userStats.$2.toString()});
          }
        });

        await platform.sendMessage(chatId, message: heroesMessage);
        await platform.sendMessage(chatId, message: heroesStatsMessage);
      });
    });
  }
}
