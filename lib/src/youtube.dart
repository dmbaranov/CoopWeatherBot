import 'dart:convert';
import 'dart:io';

class Youtube {
  final String apiKey;
  final String apiBaseUrl = 'https://www.googleapis.com/youtube/v3/search';

  Youtube(this.apiKey);

  Future<String> getYoutubeVideoUrl(String query) async {
    var url = '$apiBaseUrl?part=snippet&key=$apiKey&q=$query&maxResults=1';

    var request = await HttpClient().getUrl(Uri.parse(url));
    var response = await request.close();
    var rawResponse = '';

    await for (var contents in response.transform(Utf8Decoder())) {
      rawResponse += contents;
    }

    var responseJson = json.decode(rawResponse);

    if (responseJson['items'].length == 0) {
      return '';
    }

    var videoId = responseJson['items'][0]['id']['videoId'];
    return 'https://www.youtube.com/watch?v=$videoId';
  }
}
