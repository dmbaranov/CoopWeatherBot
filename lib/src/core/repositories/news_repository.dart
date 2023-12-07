import 'repository.dart';

class NewsRepository extends Repository {
  NewsRepository({required super.dbConnection}) : super(repositoryName: 'news');

  Future<bool> checkIfNewsExists(String chatId, String newsUrl) async {
    var foundNews = await executeQuery(queriesMap['get_single_chat_news'], {'chatId': chatId, 'newsUrl': newsUrl});

    return foundNews == null || foundNews.isNotEmpty;
  }

  Future<int> addNews(String chatId, String newsUrl) {
    return executeTransaction(queriesMap['add_news'], {'chatId': chatId, 'newsUrl': newsUrl});
  }
}
