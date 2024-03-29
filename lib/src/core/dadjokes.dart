import 'dart:convert';
import 'package:http/http.dart' as http;

const _dadjokesApiBase = 'https://icanhazdadjoke.com/';

class DadJokesJoke {
  final String joke;

  DadJokesJoke(this.joke);

  DadJokesJoke.fromJson(Map<String, dynamic> json) : joke = json['joke'];
}

class DadJokes {
  final String _apiBaseUrl = _dadjokesApiBase;

  Future<DadJokesJoke> getJoke() async {
    var response = await http.get(Uri.parse(_apiBaseUrl), headers: {'Accept': 'application/json'});
    var responseJson = jsonDecode(response.body);

    return DadJokesJoke.fromJson(responseJson);
  }
}
