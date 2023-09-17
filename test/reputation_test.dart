import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/event_bus.dart';
import 'package:weather/src/core/events/accordion_poll_events.dart';
import 'package:weather/src/core/reputation.dart';
import 'package:weather/src/core/user.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'utils/setup.dart';
import 'utils/db_connection.dart';
import 'utils/helpers.dart';

void main() {
  setupTestEnvironment();
  late EventBus eventBus;
  late Reputation reputation;
  late Chat chat;
  late User user;

  setUp(() async {
    var db = Database(DbConnection.connection);
    await db.initialize();

    chat = Chat(db: db);
    await chat.initialize();

    user = User(db: db);
    user.initialize();

    eventBus = EventBus();
    reputation = Reputation(db: db, eventBus: eventBus);
    reputation.initialize();
  });

  group('Reputation', () {
    test('should not change reputation if reputation data is not created', () async {
      await chat.createChat(id: '123', name: 'test-telegram-chat', platform: ChatPlatform.telegram);
      await user.addUser(userId: '123123', chatId: '123', name: 'test-user');
      await user.addUser(userId: '456456', chatId: '123', name: 'another-test-user');

      var result = await reputation.updateReputation(
          chatId: '123', change: ReputationChangeOption.increase, fromUserId: '123123', toUserId: '456456');

      expect(result, equals(ReputationChangeResult.userNotFound));
    });

    test('should successfully increase reputation if user is created', () async {
      await reputation.createReputationData('123', '123123');
      await reputation.createReputationData('123', '456456');

      var result = await reputation.updateReputation(
          chatId: '123', change: ReputationChangeOption.increase, fromUserId: '123123', toUserId: '456456');

      var dbData = await _getAllReputationData();
      var expectedDbData = [
        ['123123', '123', 2, 3, 0],
        ['456456', '123', 3, 3, 1]
      ];

      expect(result, equals(ReputationChangeResult.increaseSuccess));
      expect(sortResults(dbData), equals(expectedDbData));
    });

    test('should successfully decrease reputation if user is created', () async {
      await reputation.updateReputation(chatId: '123', change: ReputationChangeOption.decrease, fromUserId: '123123', toUserId: '456456');
      await reputation.updateReputation(chatId: '123', change: ReputationChangeOption.decrease, fromUserId: '123123', toUserId: '456456');
      var result = await reputation.updateReputation(
          chatId: '123', change: ReputationChangeOption.decrease, fromUserId: '123123', toUserId: '456456');

      var dbData = await _getAllReputationData();
      var expectedDbData = [
        ['123123', '123', 2, 0, 0],
        ['456456', '123', 3, 3, -2]
      ];

      expect(result, equals(ReputationChangeResult.decreaseSuccess));
      expect(sortResults(dbData), equals(expectedDbData));
    });

    test('user should not increase reputation to themselves', () async {
      var result = await reputation.updateReputation(
          chatId: '123', change: ReputationChangeOption.increase, fromUserId: '123123', toUserId: '123123');

      var dbData = await _getAllReputationData();
      var expectedDbData = [
        ['123123', '123', 2, 0, 0],
        ['456456', '123', 3, 3, -2]
      ];

      expect(result, equals(ReputationChangeResult.selfUpdate));
      expect(sortResults(dbData), equals(expectedDbData));
    });

    test('should not increase reputation if there are no vote options left', () async {
      var result = await reputation.updateReputation(
          chatId: '123', change: ReputationChangeOption.decrease, fromUserId: '123123', toUserId: '456456');

      var dbData = await _getAllReputationData();
      var expectedDbData = [
        ['123123', '123', 2, 0, 0],
        ['456456', '123', 3, 3, -2]
      ];

      expect(result, equals(ReputationChangeResult.notEnoughOptions));
      expect(sortResults(dbData), equals(expectedDbData));
    });

    test('should update reputation when accordion poll has completed', () async {
      var fromUser = await user.getSingleUserForChat('123', '123123');
      var toUser = await user.getSingleUserForChat('123', '456456');
      eventBus.fire(PollCompletedYes(chatId: '123', fromUser: fromUser!, toUser: toUser!));

      var dbData = await _getAllReputationData();
      var expectedDbData = [
        ['123123', '123', 2, 0, -1],
        ['456456', '123', 3, 3, -2]
      ];

      await Future.delayed(Duration(seconds: 1));

      expect(sortResults(dbData), equals(expectedDbData));
    }, skip: 'TODO: data is not updating in DB');
  });
}

Future<PostgreSQLResult> _getAllReputationData() {
  return DbConnection.connection.query('SELECT * FROM reputation');
}
