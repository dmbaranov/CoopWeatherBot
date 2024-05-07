import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather/src/core/config.dart';
import 'package:weather/src/injector/injection.dart';

const _youtubeApiBase = 'https://www.googleapis.com/youtube/v3/search';
const _youtubeVideoUrlBase = 'https://www.youtube.com/watch';

class Youtube {
  final Config _config;
  final String apiBaseUrl = _youtubeApiBase;

  Youtube() : _config = getIt<Config>();

  Future<String> getYoutubeVideoUrl(String query) async {
    var response = await _getYoutubeResponse(query);

    if (response['items'].length == 0) {
      return '';
    }

    var videoId = response['items'][0]['id']['videoId'];

    return '$_youtubeVideoUrlBase?v=$videoId';
  }

  Future<Map> getRawYoutubeSearchResults(String query) async {
    var response = await _getYoutubeResponse(query, 10);

    return response;
  }

  Future<Map> _getYoutubeResponse(String query, [int maxResults = 1]) async {
    var url = '$apiBaseUrl?part=snippet&key=${_config.youtubeKey}&q=$query&maxResults=$maxResults';

    var response = await http.get(Uri.parse(url));
    var responseJson = jsonDecode(response.body);

    return responseJson;
  }
}
