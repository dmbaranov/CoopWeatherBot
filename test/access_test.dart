import 'package:test/test.dart';
import 'package:weather/src/core/access.dart';
import 'package:weather/src/globals/access_level.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/modules/chat/chat.dart';
import 'package:weather/src/core/user.dart';
import 'utils/setup.dart';
import 'utils/helpers.dart';

const adminId = '369';

void main() {
  setupTestEnvironment();
  late Access access;
  late Chat chat;
  late User user;

  setUp(() async {
    chat = Chat();
    await chat.initialize();

    user = User();
    user.initialize();

    access = Access();
  });

  group('Access', () {
    test('should allow admin user to execute admin action', () async {
      await chat.createChat(id: '123', name: 'test-telegram-chat', platform: ChatPlatform.telegram);
      await user.addUser(userId: adminId, chatId: '123', name: 'admin-user');

      var successCallbackCalled = false;
      var failureCallbackCalled = false;

      access.execute(
          event: getFakeMessageEvent(userId: adminId),
          command: 'test-command',
          accessLevel: AccessLevel.admin,
          onSuccess: (messageEvent) {
            successCallbackCalled = true;
          },
          onFailure: (messageEvent) {
            failureCallbackCalled = true;

            return Future.value(null);
          });

      await Future.delayed(Duration(seconds: 1));

      expect(successCallbackCalled, equals(true));
      expect(failureCallbackCalled, equals(false));
    }, skip: 'TODO: get rid of Future.delayed');
  });
}
