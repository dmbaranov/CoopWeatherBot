import 'package:collection/collection.dart';
import 'package:cron/cron.dart';
import 'package:nyxx/nyxx.dart' hide Logger, User;
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:weather/src/core/repositories/hero_stats_repository.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/injector/injection.dart';
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

      if (event.status == UserStatus.online) {
        (_usersOnlineStatus[guildId] ??= {})[userId] = true;
      } else {
        (_usersOnlineStatus[guildId] ??= {})[userId] = false;
      }
    });
  }

  void _startHeroCheckJob() {
    Cron().schedule(Schedule.parse('0 4 * * 6,0'), () async {
      var authorizedChats = await modulesMediator.chat.getAllChatIdsForPlatform(ChatPlatform.discord);

      await Future.forEach(authorizedChats, (chatId) async {
        var chatOnlineUsers = _usersOnlineStatus[chatId];
        if (chatOnlineUsers == null) {
          _logger.w('Attempt to get online users for empty chat $chatId');

          return null;
        }

        var listOfOnlineUsers = chatOnlineUsers.entries.where((entry) => entry.value == true).map((entry) => entry.key).toList();
        if (listOfOnlineUsers.isEmpty) {
          return platform.sendMessage(chatId, translation: 'hero.users_at_five.no_users');
        }

        var chatUsers = await modulesMediator.user.getUsersForChat(chatId);
        var chatUserStats = await _heroStatsDb.getChatHeroStats(chatId);
        var heroesMessage = _sw.getText(chatId, 'hero.users_at_five.list');
        var heroesStatsMessage = _sw.getText(chatId, 'hero.users_at_five.stats');

        listOfOnlineUsers.forEach((userId) {
          var onlineUser = chatUsers.firstWhereOrNull((user) => user.id == userId);

          if (onlineUser != null) {
            heroesMessage += onlineUser.name;
            heroesMessage += '\n';

            var onlineUserStats = chatUserStats.firstWhereOrNull((userStats) => userStats.$1 == userId);

            if (onlineUserStats != null) {
              heroesStatsMessage +=
                  _sw.getText(chatId, 'hero.users_at_five.hero_stats', {'hero': onlineUser.name, 'count': onlineUserStats.$2.toString()});
            }
          }
        });

        await platform.sendMessage(chatId, message: heroesMessage);
        await platform.sendMessage(chatId, message: heroesStatsMessage);
      });
    });
  }
}
