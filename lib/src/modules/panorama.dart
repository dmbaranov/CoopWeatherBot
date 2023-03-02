import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

const String _pathToCacheFile = 'assets/panorama_news_cache.txt';
const String _panoramaBaseUrl = 'https://panorama.pub';

class NewsData {
  final String title;
  final String url;

  NewsData(this.title, this.url);

  NewsData.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        url = json['url'];
}

class PanoramaNews {
  final String _newsBaseUrl = _panoramaBaseUrl;
  final io.File _savedNewsFile = io.File(_pathToCacheFile);
  final Map<String, int> _cache = {};

  Future<void> initialize() async {
    var newsFromFile = await _savedNewsFile.readAsLines();

    newsFromFile.forEach((title) {
      _cache[title] = 1;
    });
  }

  Future<NewsData> getNews() async {
    await _clearCache();

    var response = await http.get(Uri.parse(_newsBaseUrl));
    var document = parser.parse(response.body);

    var posts = document.querySelector('.container ul.mt-4')?.querySelectorAll('a');

    if (posts == null) {
      return NewsData('', '');
    }

    var result = {'title': ''};

    for (var i = 0; i < posts.length; i++) {
      var post = posts[i];
      var postHref = post.attributes['href'];

      if (postHref == null || !postHref.startsWith('/news')) continue;

      var title = post.querySelector('.text-sm > div')?.text;

      if (title == null || _cache[title] != null) continue;

      result = {'title': title, 'url': _newsBaseUrl + postHref};

      _cache[title] = 1;
      _writeToCacheFile(title);
      break;
    }

    return NewsData.fromJson(result);
  }

  Future<void> _clearCache() async {
    var maxCacheSize = 100;
    var numberOfSavedNewsToKeep = 10;

    if (_cache.length > maxCacheSize) {
      // If there are too many news in the cache file, erase the content, but save
      // x amount of latest news to avoid duplications
      var savedNews = await _savedNewsFile.readAsLines();
      var updatedCacheNews = savedNews.sublist(savedNews.length - numberOfSavedNewsToKeep);

      await _overwriteCacheFile(updatedCacheNews);
    }
  }

  void _writeToCacheFile(String title) {
    _savedNewsFile.writeAsStringSync('$title\n', mode: io.FileMode.append);
  }

  Future<void> _overwriteCacheFile(List<String> news) async {
    for (var i = 0; i < news.length; i++) {
      var newsTitle = news[i];

      if (i == 0) {
        // First iteration should erase previous content
        await _savedNewsFile.writeAsString('$newsTitle\n');
      } else {
        await _savedNewsFile.writeAsString('$newsTitle\n', mode: io.FileMode.append);
      }
    }
  }
}
