import 'dart:convert';
import 'dart:io';

class OpenWeatherData {
  final String city;
  final num temp;

  OpenWeatherData(this.city, this.temp);

  OpenWeatherData.fromJson(Map<String, dynamic> json)
      : city = json['city'],
        temp = json['temp'];

  Map<String, dynamic> toJson() => {'city': city, 'temp': temp};
}

class OpenWeather {
  final String apiKey;
  final String apiBaseUrl = "https://api.openweathermap.org/data/2.5";

  OpenWeather(this.apiKey);

  Future<OpenWeatherData> getCurrentWeather(String city) async {
    var url = '$apiBaseUrl/weather?q=$city&appid=$apiKey&units=metric';

    var request = await HttpClient().getUrl(Uri.parse(url));
    var response = await request.close();
    var rawResponse = '';

    await for (var contents in response.transform(Utf8Decoder())) {
      rawResponse += contents;
    }

    var responseJson = json.decode(rawResponse);
    var rawWeatherData = {
      'city': responseJson['name'],
      'temp': responseJson['main']['temp']
    };

    return OpenWeatherData.fromJson(rawWeatherData);
  }
}
