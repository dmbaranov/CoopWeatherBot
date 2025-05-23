// import 'package:test/test.dart';
// import 'package:postgres/postgres.dart';
// import 'package:weather/src/modules/user/user.dart';
// import 'package:weather/src/modules/chat/chat.dart';
// import 'package:weather/src/globals/chat_platform.dart';
// import 'utils/setup.dart';
// import 'utils/db_connection.dart';
// import 'utils/helpers.dart';
//
// void main() {
//   setupTestEnvironment();
//   late User user;
//   late Chat chat;
//
//   setUp(() async {
//     user = User();
//     user.initialize();
//
//     chat = Chat();
//   });
//
//   group('User', () {
//     test('adds a new user', () async {
//       await chat.createChat(id: '123', name: 'test-telegram-chat', platform: ChatPlatform.telegram);
//       await chat.createChat(id: '456', name: 'test-discord-chat', platform: ChatPlatform.discord);
//       await user.addUser(userId: '123123', chatId: '123', name: 'test-telegram-user-name');
//       await user.addUser(userId: '456456', chatId: '456', name: 'test-discord-user-name');
//
//       var dbUsers = await _getAllUsers();
//       var expectedUsers = [
//         ['123123', 'test-telegram-user-name', false],
//         ['456456', 'test-discord-user-name', false]
//       ];
//
//       var dbChatMembers = await _getAllChatMembers();
//       var expectedChatMembers = [
//         ['123123', '123', false, false, false],
//         ['456456', '456', false, false, false]
//       ];
//
//       expect(sortResults(dbUsers), equals(expectedUsers));
//       expect(sortResults(dbChatMembers), equals(expectedChatMembers));
//     });
//
//     test('receives a single user by id', () async {
//       var foundUser = await user.getSingleUserForChat('123', '123123');
//       var expected = {
//         'id': '123123',
//         'name': 'test-telegram-user-name',
//         'isPremium': false,
//         'deleted': false,
//         'banned': false,
//         'moderator': false
//       };
//
//       expect(foundUser?.toJson(), equals(expected));
//     });
//
//     test('receives all users for the chat', () async {
//       var rawFoundUsers = await user.getUsersForChat('123');
//       var foundUsers = rawFoundUsers.map((user) => user.toJson());
//       var expectedUsers = [
//         {'id': '123123', 'name': 'test-telegram-user-name', 'isPremium': false, 'deleted': false, 'banned': false, 'moderator': false}
//       ];
//
//       expect(foundUsers, equals(expectedUsers));
//     });
//
//     test('deletes a user', () async {
//       await user.removeUser('123', '123123');
//
//       var dbData = await _getAllChatMembers();
//       var expected = [
//         ['123123', '123', true, false, false],
//         ['456456', '456', false, false, false]
//       ];
//
//       expect(sortResults(dbData), equals(expected));
//     });
//
//     test('updates a premium status for the user', () async {
//       await user.updatePremiumStatus('456456', true);
//       var foundUser = await user.getSingleUserForChat('456', '456456');
//       var expectedUser = {
//         'id': '456456',
//         'name': 'test-discord-user-name ⭐',
//         'isPremium': true,
//         'deleted': false,
//         'banned': false,
//         'moderator': false
//       };
//
//       var dbData = await _getAllUsers();
//       var expectedDbData = [
//         ['123123', 'test-telegram-user-name', false],
//         ['456456', 'test-discord-user-name', true]
//       ];
//
//       expect(foundUser?.toJson(), equals(expectedUser));
//       expect(sortResults(dbData), equals(expectedDbData));
//     });
//   });
// }
//
// Future<Result> _getAllUsers() {
//   return DbConnection.connection.execute('SELECT * FROM bot_user');
// }
//
// Future<Result> _getAllChatMembers() {
//   return DbConnection.connection.execute('SELECT * FROM chat_member');
// }
