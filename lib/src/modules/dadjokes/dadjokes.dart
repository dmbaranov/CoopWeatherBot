import 'dart:convert';

import 'package:http/http.dart' as http;

class DadJokesJoke {
  final String joke;

  DadJokesJoke(this.joke);

  DadJokesJoke.fromJson(Map<String, dynamic> json) : joke = json['joke'];

  Map<String, dynamic> toJson() => {'joke': joke};
}

class DadJokes {
  final String _apiBaseUrl = 'https://icanhazdadjoke.com/';

  Future<DadJokesJoke> getJoke() async {
    var response = await http.get(Uri.parse(_apiBaseUrl));
    var responseJson = jsonDecode(response.body);
    // TODO: is this needed?
    var rawJoke = {'joke': responseJson['joke']};

    return DadJokesJoke.fromJson(rawJoke);
  }
}
