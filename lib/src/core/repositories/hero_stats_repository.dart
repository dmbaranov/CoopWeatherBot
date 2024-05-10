import 'package:injectable/injectable.dart';
import 'repository.dart';

@singleton
class HeroStatsRepository extends Repository {
  HeroStatsRepository({required super.db}) : super(repositoryName: 'hero_stats');

  Future<List<(String, int)>> getChatHeroStats(String chatId) async {
    var rawStats = await db.executeQuery(queriesMap['get_chat_hero_stats'], {'chatId': chatId});

    if (rawStats == null || rawStats.isEmpty) {
      return [];
    }

    return rawStats
        .map<Map<String, dynamic>>((userStats) => userStats.toColumnMap())
        .map<(String, int)>((stats) => (stats['bot_user_id'], stats['stats']))
        .toList();
  }

  Future<int> createHeroRecord(String chatId, String userId, String timestamp) async {
    return db.executeTransaction(queriesMap['create_hero_record'], {'chatId': chatId, 'userId': userId, 'timestamp': timestamp});
  }
}
