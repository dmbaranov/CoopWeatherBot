import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

// TODO: remove initial news, it's a hotfix
Map<String, int> _cache = {'Лукашенко реорганизует республику в Первую белорусскую империю': 1};
var _cacheSize = 10; // This needs to be increased if news are repeating

class NewsData {
  final String title;
  final String content;

  NewsData(this.title, this.content);

  NewsData.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        content = json['content'];

  Map<String, dynamic> toJson() => {'city': title, 'temp': content};
}

void clearCache() {
  if (_cache.length > _cacheSize) {
    _cache = {};
  }
}

Future<NewsData> getNews() async {
  clearCache();

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
    break;
  }

  return NewsData.fromJson(result);
}
