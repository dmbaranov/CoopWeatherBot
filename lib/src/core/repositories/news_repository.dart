import 'package:injectable/injectable.dart';
import 'repository.dart';

@singleton
class NewsRepository extends Repository {
  NewsRepository({required super.db}) : super(repositoryName: 'news');

  Future<int?> getSingleNewsIdForChat(String chatId, String newsUrl) async {
    var foundNews = await db.executeQuery(queriesMap['get_single_chat_news_id'], {'chatId': chatId, 'newsUrl': newsUrl});

    if (foundNews != null && foundNews.isNotEmpty) {
      return foundNews[0].toColumnMap()['id'];
    }

    return null;
  }

  Future<int> addNews(String chatId, String newsUrl) {
    return db.executeTransaction(queriesMap['add_news'], {'chatId': chatId, 'newsUrl': newsUrl});
  }
}
