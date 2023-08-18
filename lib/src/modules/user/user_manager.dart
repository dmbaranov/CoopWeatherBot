import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/modules/utils.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/user.dart';
import 'package:weather/src/core/chat.dart';

class UserManager {
  final Platform platform;
  final Database db;

  late User _user;
  late Chat _chat;

  UserManager({required this.platform, required this.db}) {
    _user = User(db: db);
    _chat = Chat(db: db);
  }

  void initialize() {
    _user.initialize();

    _subscribeToUserUpdates()
  }

  void addUser(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.otherUserIds[0];
    var username = event.parameters[0];
    var isPremium = event.parameters[1] == 'true';
    var result = await _user.addUser(userId: userId, chatId: chatId, name: username, isPremium: isPremium);
    var successfulMessage = _chat.getText(chatId, 'user.user_added');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void removeUser(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.otherUserIds[0];
    var result = await _user.removeUser(userId);
    var successfulMessage = _chat.getText(chatId, 'user.user_removed');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void _subscribeToUserUpdates() {
    _user.userManagerStream.listen((_) {
      _updateUsersPremiumStatus();
    });
  }

  Future<void> _updateUsersPremiumStatus() async {
    var allPlatformChatIds = await _chat.getAllChatIdsForPlatform(platform.chatPlatform);

    await Future.forEach(allPlatformChatIds, (chatId) async {
      var chatUsers = await _user.getUsersForChat(chatId);

      await Future.forEach(chatUsers, (chatUser) async {
        await Future.delayed(Duration(seconds: 1));

        var platformUserPremiumStatus = await platform.getUserPremiumStatus(chatId, chatUser.id);

        if (chatUser.isPremium != platformUserPremiumStatus) {
          print('Updating premium status for ${chatUser.id}');

          await _user.updatePremiumStatus(chatUser.id, platformUserPremiumStatus);
        }
      });
    });
  }
}
