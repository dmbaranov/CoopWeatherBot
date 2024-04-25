import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/modules/chat/chat.dart';
import 'utils/setup.dart';
import 'utils/db_connection.dart';
import 'utils/helpers.dart';

void main() {
  setupTestEnvironment();
  late Chat chat;

  setUp(() async {
    chat = Chat();
  });

  group('Chat', () {
    test('should create a new Telegram chat', () async {
      await chat.createChat(id: '123', name: 'test-telegram-chat', platform: ChatPlatform.telegram);
      await chat.createChat(id: '456', name: 'test-discord-chat', platform: ChatPlatform.discord);
      var dbData = await _getAllChats();
      var expected = [
        ['123', 'test-telegram-chat', 'telegram', 'basic'],
        ['456', 'test-discord-chat', 'discord', 'basic']
      ];

      expect(sortResults(dbData), equals(expected));
    });

    test('should update swearwords config for the chat', () async {
      await chat.setSwearwordsConfig('123', 'sample');
      var dbData = await _getAllChats();
      var expected = [
        ['123', 'test-telegram-chat', 'telegram', 'sample'],
        ['456', 'test-discord-chat', 'discord', 'basic']
      ];

      expect(sortResults(dbData), equals(expected));
    });

    test('should get all chat ids for the platform', () async {
      var allChats = await chat.getAllChatIdsForPlatform(ChatPlatform.telegram);
      var expected = ['123'];

      expect(allChats, equals(expected));
    });
  });
}

Future<Result> _getAllChats() {
  return DbConnection.connection.execute('SELECT * FROM chat');
}
