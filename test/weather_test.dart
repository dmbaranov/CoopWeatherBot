import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/weather.dart';
import 'utils/setup.dart';
import 'utils/db_connection.dart';
import 'utils/helpers.dart';

void main() {
  setupTestEnvironment();
  late Chat chat;
  late Weather weather;

  setUp(() async {
    var db = Database(DbConnection.connection);
    await db.initialize();

    chat = Chat(db: db);
    await chat.initialize();

    weather = Weather(db: db, openweatherKey: 'no-key-provided');
    weather.initialize();
  });

  group('Weather', () {
    test('should create weather data for the chat', () async {
      await chat.createChat(id: '123', name: 'test-telegram-chat', platform: ChatPlatform.telegram);
      await weather.createWeatherData('123');

      var dbData = await _getAllWeather();
      var expectedDbData = [
        ['123', null, 7]
      ];

      expect(sortResults(dbData), equals(expectedDbData));
    });

    test('should add cities for the chat', () async {
      await weather.addCity('123', 'New York');
      await weather.addCity('123', 'Los Angeles');

      var dbData = await _getAllWeather();
      var expectedDbData = [
        ['123', 'New York,Los Angeles', 7]
      ];

      expect(sortResults(dbData), equals(expectedDbData));
    });

    test('should not set incorrect notification hour for the chat', () async {
      await weather.setNotificationHour('123', 25);

      var dbData = await _getAllWeather();
      var expectedDbData = [
        ['123', 'New York,Los Angeles', 7]
      ];

      expect(sortResults(dbData), equals(expectedDbData));
    });

    test('should change notification hour for the chat', () async {
      await weather.setNotificationHour('123', 8);

      var dbData = await _getAllWeather();
      var expectedDbData = [
        ['123', 'New York,Los Angeles', 8]
      ];

      expect(sortResults(dbData), equals(expectedDbData));
    });

    test('should get watchlist for the chat', () async {
      var watchlist = await weather.getWatchList('123');
      var expectedWatchlist = ['New York', 'Los Angeles'];

      expect(watchlist, expectedWatchlist);
    });

    test('should remove city for the chat', () async {
      await weather.removeCity('123', 'New York');

      var dbData = await _getAllWeather();
      var expectedDbData = [
        ['123', 'Los Angeles', 8]
      ];

      expect(sortResults(dbData), equals(expectedDbData));
    });
  });
}

Future<Result> _getAllWeather() {
  return DbConnection.connection.execute('SELECT * FROM weather');
}
