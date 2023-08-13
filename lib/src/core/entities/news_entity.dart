import 'entity.dart';

class NewsEntity extends Entity {
  NewsEntity({required super.dbConnection}) : super(entityName: 'news');

  Future<bool> checkIfNewsExists(String chatId, String newsUrl) async {
    var foundNews = await executeQuery(queriesMap['check_if_news_exists'], {'chatId': chatId, 'newsUrl': newsUrl});

    return foundNews == null || foundNews.isNotEmpty;
  }

  Future<int> addNews(String chatId, String newsUrl) {
    return executeTransaction(queriesMap['add_news'], {'chatId': chatId, 'newsUrl': newsUrl});
  }
}
