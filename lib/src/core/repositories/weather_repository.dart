import 'package:weather/src/core/weather.dart' show ChatNotificationHour;
import 'repository.dart';

class WeatherRepository extends Repository {
  WeatherRepository({required super.dbConnection}) : super(repositoryName: 'weather');

  Future<int> createWeatherData(String chatId, int notificationHour) {
    return executeTransaction(queriesMap['create_weather_data'], {'chatId': chatId, 'notificationHour': notificationHour});
  }

  Future<int> updateCities(String chatId, List<String> cities) {
    var citiesString = cities.join(',');

    return executeTransaction(queriesMap['update_cities'], {'chatId': chatId, 'cities': citiesString});
  }

  Future<int> setNotificationHour(String chatId, int notificationHour) {
    return executeTransaction(queriesMap['set_notification_hour'], {'chatId': chatId, 'notificationHour': notificationHour});
  }

  Future<List<ChatNotificationHour>> getNotificationHours() async {
    var hoursForChats = await executeQuery(queriesMap['get_notification_hours']);

    if (hoursForChats == null || hoursForChats.isEmpty) {
      return [];
    }

    return hoursForChats.map((config) => ChatNotificationHour(chatId: config[0] as String, notificationHour: config[1] as int)).toList();
  }

  Future<List<String>?> getCities(String chatId) async {
    var data = await executeQuery(queriesMap['get_cities'], {'chatId': chatId});

    if (data == null || data.isEmpty) {
      return [];
    }

    if (data.length != 1) {
      print('One piece of cities data was expected, got ${data.length} instead');

      return null;
    }

    var citiesData = data[0];

    return (citiesData[0] as String?)?.split(',');
  }
}
