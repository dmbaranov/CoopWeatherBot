import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:weather/src/modules/database-manager/database_manager.dart';

const String _panoramaBaseUrl = 'https://panorama.pub';

class NewsData {
  final String title;
  final String url;

  NewsData({required this.title, required this.url});
}

class PanoramaNews {
  final DatabaseManager dbManager;
  final String _newsBaseUrl = _panoramaBaseUrl;

  PanoramaNews({required this.dbManager});

  Future<NewsData?> getNews(String chatId) async {
    var response = await http.get(Uri.parse(_newsBaseUrl));
    var document = parser.parse(response.body);

    var posts = document.querySelector('.container ul.mt-4')?.querySelectorAll('a');

    if (posts == null) {
      return null;
    }

    for (var i = 0; i < posts.length; i++) {
      var post = posts[i];
      var postHref = post.attributes['href'];

      if (postHref == null || !postHref.startsWith('/news')) {
        continue;
      }

      var title = post.querySelector('.text-sm > div')?.text;

      var newsWasSentBefore = await dbManager.news.checkIfNewsExists(chatId, postHref);

      if (title == null || newsWasSentBefore) {
        continue;
      }

      var createResult = await dbManager.news.addNews(chatId, postHref);

      if (createResult == 1) {
        return NewsData(title: title, url: _newsBaseUrl + postHref);
      }
    }

    return null;
  }
}
