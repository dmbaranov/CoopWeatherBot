import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/chat.dart';
import 'utils/setup.dart';
import 'utils/db_connection.dart';

void main() {
  setupTestEnvironment();
  late Chat chat;
  const testChatId = '123';

  setUp(() async {
    var db = Database(DbConnection.connection);
    await db.initialize();

    chat = Chat(db: db);
    await chat.initialize();
  });

  group('Chat', () {
    test('should create a new Telegram chat', () async {
      await chat.createChat(id: testChatId, name: 'test-chat', platform: ChatPlatform.telegram);
      var dbData = await _getAllChats();
      var expected = [
        ['123', 'test-chat', 'telegram', 'basic']
      ];

      expect(dbData, equals(expected));
    });

    test('should update swearwords config for the chat', () async {
      await chat.setSwearwordsConfig(testChatId, 'sample');
      var dbData = await _getAllChats();
      var expected = [
        ['123', 'test-chat', 'telegram', 'sample']
      ];

      expect(dbData, equals(expected));
    });

    test('should get all chat ids for the platform', () async {
      var allChats = await chat.getAllChatIdsForPlatform(ChatPlatform.telegram);
      var expected = ['123'];

      expect(allChats, equals(expected));
    });

    test('should return correct translation based on swearwords config', () {
      var text = chat.getText(testChatId, 'chat.initialization.success');
      var expected = 'Чат инициализирован успешно';

      expect(text, equals(expected));
    });
  });
}

Future<PostgreSQLResult> _getAllChats() {
  return DbConnection.connection.query('SELECT * FROM chat');
}
