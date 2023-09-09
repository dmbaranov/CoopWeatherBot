import 'package:test/test.dart';
import 'package:postgres/postgres.dart';
import 'package:weather/src/core/user.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'utils/setup.dart';
import 'utils/db_connection.dart';
import 'utils/helpers.dart';

// TODO: use raw SQL queries instead
void main() {
  setupTestEnvironment();
  late User user;
  late Chat chat;

  setUp(() async {
    var db = Database(DbConnection.connection);
    await db.initialize();

    user = User(db: db);
    user.initialize();

    chat = Chat(db: db);
    await chat.initialize();
  });

  group('User', () {
    test('adds a new user', () async {
      await chat.createChat(id: '123', name: 'test-telegram-chat', platform: ChatPlatform.telegram);
      await chat.createChat(id: '456', name: 'test-discord-chat', platform: ChatPlatform.discord);
      await user.addUser(userId: '123123', chatId: '123', name: 'test-telegram-user-name');
      await user.addUser(userId: '456456', chatId: '456', name: 'test-discord-user-name');

      var dbData = await _getAllUsers();
      var expected = [
        ['123123', 'test-telegram-user-name', false],
        ['456456', 'test-discord-user-name', false]
      ];

      expect(sortResults(dbData), equals(expected));
    });

    test('receives a single user by id', () async {
      var foundUser = await user.getSingleUserForChat('123', '123123');
      var expected = {
        'id': '123123',
        'name': 'test-telegram-user-name',
        'isPremium': false,
        'deleted': false,
        'banned': false,
        'moderator': false
      };

      expect(foundUser?.toJson(), equals(expected));
    });

    test('receives all users for the chat', () async {
      var rawFoundUsers = await user.getUsersForChat('123');
      var foundUsers = rawFoundUsers.map((user) => user.toJson());
      var expected = [
        {'id': '123123', 'name': 'test-telegram-user-name', 'isPremium': false, 'deleted': false, 'banned': false, 'moderator': false}
      ];

      expect(foundUsers, equals(expected));
    });

    test('deletes a user', () async {
      await user.removeUser('123', '123123');
      var foundUser = await user.getSingleUserForChat('123', '123123');
      var expected = {
        'id': '123123',
        'name': 'test-telegram-user-name',
        'isPremium': false,
        'deleted': true,
        'banned': false,
        'moderator': false
      };

      expect(foundUser?.toJson(), equals(expected));
    });

    test('updates a premium status for the user', () async {
      await user.updatePremiumStatus('456456', true);
      var foundUser = await user.getSingleUserForChat('456', '456456');
      var expected = {
        'id': '456456',
        'name': 'test-discord-user-name ⭐',
        'isPremium': true,
        'deleted': false,
        'banned': false,
        'moderator': false
      };

      expect(foundUser?.toJson(), equals(expected));
    });
  });
}

Future<PostgreSQLResult> _getAllUsers() {
  return DbConnection.connection.query('SELECT * FROM bot_user');
}
