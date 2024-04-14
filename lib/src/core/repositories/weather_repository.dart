import 'package:injectable/injectable.dart';
import 'package:weather/src/core/weather.dart' show ChatNotificationHour;
import 'repository.dart';

@singleton
class WeatherRepository extends Repository {
  WeatherRepository({required super.db}) : super(repositoryName: 'weather');

  Future<int> createWeatherData(String chatId, int notificationHour) {
    return db.executeTransaction(queriesMap['create_weather_data'], {'chatId': chatId, 'notificationHour': notificationHour});
  }

  Future<int> updateCities(String chatId, List<String> cities) {
    var citiesString = cities.isNotEmpty ? cities.join(',') : null;

    return db.executeTransaction(queriesMap['update_cities'], {'chatId': chatId, 'cities': citiesString});
  }

  Future<int> setNotificationHour(String chatId, int notificationHour) {
    return db.executeTransaction(queriesMap['set_notification_hour'], {'chatId': chatId, 'notificationHour': notificationHour});
  }

  Future<List<ChatNotificationHour>> getNotificationHours() async {
    var hoursForChats = await db.executeQuery(queriesMap['get_notification_hours']);

    if (hoursForChats == null || hoursForChats.isEmpty) {
      return [];
    }

    return hoursForChats
        .map((config) => config.toColumnMap())
        .map((config) => ChatNotificationHour(chatId: config['chat_id'], notificationHour: config['notification_hour']))
        .toList();
  }

  Future<List<String>?> getCities(String chatId) async {
    var data = await db.executeQuery(queriesMap['get_cities'], {'chatId': chatId});

    if (data == null || data.isEmpty) {
      return [];
    }

    var citiesData = data[0].toColumnMap();

    return citiesData['cities']?.split(',');
  }
}
