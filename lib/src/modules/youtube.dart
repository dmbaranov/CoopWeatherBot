import 'dart:convert';
import 'dart:io';

class Youtube {
  final String apiKey;
  final String apiBaseUrl = 'https://www.googleapis.com/youtube/v3/search';

  Youtube(this.apiKey);

  Future<Map> _getYoutubeResponse(String query, [int maxResults = 1]) async {
    var url = '$apiBaseUrl?part=snippet&key=$apiKey&q=$query&maxResults=$maxResults';

    var request = await HttpClient().getUrl(Uri.parse(url));
    var response = await request.close();
    var rawResponse = '';

    await for (var contents in response.transform(Utf8Decoder())) {
      rawResponse += contents;
    }

    var responseJson = json.decode(rawResponse);

    return responseJson;
  }

  Future<String> getYoutubeVideoUrl(String query) async {
    var response = await _getYoutubeResponse(query);

    if (response['items'].length == 0) {
      return '';
    }

    var videoId = response['items'][0]['id']['videoId'];
    
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  Future<Map> getYoutubeSearchResults(String query) async {
    var response = await _getYoutubeResponse(query, 10);

    return response;
  }
}
