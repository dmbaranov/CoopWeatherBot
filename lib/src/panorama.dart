import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

Map<String, int> _cache = {};
const String _pathToCacheFile = 'assets/panorama_news_cache.txt';
const String panoramaBaseUrl = 'https://panorama.pub';

class NewsData {
  final String title;
  final String url;

  NewsData(this.title, this.url);

  NewsData.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        url = json['url'];
}

Future<void> setupPanoramaNews() async {
  var savedNewsFile = io.File(_pathToCacheFile);
  var savedNews = await savedNewsFile.readAsLines();

  savedNews.forEach((title) {
    _cache[title] = 1;
  });
}

Future<void> _clearCache() async {
  var cacheSize = 100;
  var saveNumberOfPreviousNews = 10;

  if (_cache.length > cacheSize) {
    // If there are too many news in the cache file, erase the content, but save
    // x amount of latest news to avoid duplications
    var cacheFile = io.File(_pathToCacheFile);
    var news = await cacheFile.readAsLines();
    var newsForUpdatedCache = news.sublist(news.length - saveNumberOfPreviousNews);

    await _overwriteCacheFile(newsForUpdatedCache);
  }
}

Future<void> _writeToCacheFile(String title) async {
  var cacheFile = io.File(_pathToCacheFile);

  cacheFile.writeAsStringSync('$title\n', mode: io.FileMode.append);
}

Future<void> _overwriteCacheFile(List<String> content) async {
  var cacheFile = io.File(_pathToCacheFile);

  for (var i = 0; i < content.length; i++) {
    var value = content[i];

    if (i == 0) {
      // First iteration should erase previous content
      await cacheFile.writeAsString('$value\n');
    } else {
      await cacheFile.writeAsString('$value\n', mode: io.FileMode.append);
    }
  }
}

Future<NewsData> getNews() async {
  await _clearCache();

  var response = await http.get(Uri.parse(panoramaBaseUrl));
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

    result = {'title': title, 'url': panoramaBaseUrl + postHref};

    _cache[title] = 1;
    await _writeToCacheFile(title);
    break;
  }

  return NewsData.fromJson(result);
}
