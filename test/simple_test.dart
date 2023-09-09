import 'package:test/test.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'docker.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/chat.dart';

void main() {
  runDocker();

  test('Some simple test', () async {
    var dbConnection = await getConnection();
    var db = Database(dbConnection);
    await db.initialize();
    var chat = Chat(db: db);
    await chat.initialize();

    await chat.createChat(id: '123', name: 'Test chat', platform: ChatPlatform.telegram);

    var allChats = await chat.getAllChatIdsForPlatform(ChatPlatform.telegram);
    expect(allChats.length, equals(1));
  });
}
