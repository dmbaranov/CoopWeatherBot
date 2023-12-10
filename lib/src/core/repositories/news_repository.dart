import 'repository.dart';

class NewsRepository extends Repository {
  NewsRepository({required super.dbConnection}) : super(repositoryName: 'news');

  Future<int?> getSingleNewsIdForChat(String chatId, String newsUrl) async {
    var foundNews = await executeQuery(queriesMap['get_single_chat_news_id'], {'chatId': chatId, 'newsUrl': newsUrl});

    if (foundNews != null && foundNews.isNotEmpty) {
      return foundNews[0].toColumnMap()['id'];
    }
    
    return null;
  }

  Future<int> addNews(String chatId, String newsUrl) {
    return executeTransaction(queriesMap['add_news'], {'chatId': chatId, 'newsUrl': newsUrl});
  }
}
