import 'entity.dart';

class ChatNotificationHour {
  final String chatId;
  final int notificationHour;

  ChatNotificationHour({required this.chatId, required this.notificationHour});
}

class WeatherEntity extends Entity {
  WeatherEntity({required super.dbConnection}) : super(entityName: 'weather');

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

    return hoursForChats.map((config) => ChatNotificationHour(chatId: config[0], notificationHour: config[1])).toList();
  }

  Future<List<String>?> getCities(String chatId) async {
    var data = await executeQuery(queriesMap['get_cities'], {'chatId': chatId});

    if (data.length != 1) {
      print('One piece of data was expected, got ${data.length} instead');

      return null;
    }

    var citiesData = data[0];

    return citiesData[0]?.split(',');
  }
}
