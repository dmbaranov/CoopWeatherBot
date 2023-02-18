import 'dart:convert';
import 'dart:io';

const _dadJokesUrl = 'https://icanhazdadjoke.com/';

class DadJokesJoke {
  final String joke;

  DadJokesJoke(this.joke);

  DadJokesJoke.fromJson(Map<String, dynamic> json) : joke = json['joke'];

  Map<String, dynamic> toJson() => {'joke': joke};
}

class DadJokes {
  final String _apiBaseUrl = _dadJokesUrl;

  Future<DadJokesJoke> getJoke() async {
    var request = await HttpClient().getUrl(Uri.parse(_apiBaseUrl));
    request.headers.add('Accept', 'application/json');

    var response = await request.close();
    var rawResponse = '';

    await for (var contents in response.transform(Utf8Decoder())) {
      rawResponse += contents;
    }

    var responseJson = json.decode(rawResponse);
    var rawJoke = {'joke': responseJson['joke']};

    return DadJokesJoke.fromJson(rawJoke);
  }
}
