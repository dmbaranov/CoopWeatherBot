import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

Map<String, int> _cache = {};
String _pathToCacheFile = 'assets/panorama_news_cache.txt';

class NewsData {
  final String title;
  final String content;

  NewsData(this.title, this.content);

  NewsData.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        content = json['content'];

  Map<String, dynamic> toJson() => {'city': title, 'temp': content};
}

void setupPanoramaNews() async {
  var savedNewsFile = io.File(_pathToCacheFile);
  var savedNews = await savedNewsFile.readAsLines();

  savedNews.forEach((title) {
    _cache[title] = 1;
  });
}

void _clearCache() async {
  var cacheSize = 100;
  var saveNumberOfPreviousNews = 10;

  if (_cache.length > cacheSize) {
    // If there're too many news in the cache file, erase the content, but save
    // x amount of latest news to avoid duplications
    var cacheFile = io.File(_pathToCacheFile);
    var news = await cacheFile.readAsLines();
    var newsForUpdatedCache = news.sublist(news.length - saveNumberOfPreviousNews);

    await _overwriteCacheFile(newsForUpdatedCache);
  }
}

void _writeToCacheFile(String title) async {
  var cacheFile = io.File(_pathToCacheFile);

  await cacheFile.writeAsStringSync('$title\n', mode: io.FileMode.append);
}

void _overwriteCacheFile(List<String> content) async {
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

  var response = await http.get('https://panorama.pub/');
  var document = parser.parse(response.body);

  var posts = document.querySelectorAll('.np-primary-block-wrap .np-single-post');

  var result = {'title': '', 'content': ''};

  for (var i = 0; i < posts.length; i++) {
    var elem = posts[i];
    var title = elem.querySelector('.np-post-title').text;

    if (_cache[title] != null) continue;

    var content = elem.querySelector('.np-post-excerpt').text;

    result = {'title': title, 'content': content};

    _cache[title] = 1;
    await _writeToCacheFile(title);
    break;
  }

  return NewsData.fromJson(result);
}
