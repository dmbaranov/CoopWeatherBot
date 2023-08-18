import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/modules/utils.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/user.dart';
import 'package:weather/src/core/chat.dart';

class UserManager {
  final Platform platform;
  final Database db;
  final Chat chat;
  final User user;

  UserManager({required this.platform, required this.db, required this.chat, required this.user});

  void initialize() {
    _subscribeToUserUpdates();
  }

  void addUser(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.otherUserIds[0];
    var username = event.parameters[0];
    var isPremium = event.parameters[1] == 'true';
    var result = await user.addUser(userId: userId, chatId: chatId, name: username, isPremium: isPremium);
    var successfulMessage = chat.getText(chatId, 'user.user_added');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void removeUser(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.otherUserIds[0];
    var result = await user.removeUser(chatId, userId);
    var successfulMessage = chat.getText(chatId, 'user.user_removed');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void _subscribeToUserUpdates() {
    user.userManagerStream.listen((_) {
      _updateUsersPremiumStatus();
    });
  }

  Future<void> _updateUsersPremiumStatus() async {
    var allPlatformChatIds = await chat.getAllChatIdsForPlatform(platform.chatPlatform);

    await Future.forEach(allPlatformChatIds, (chatId) async {
      var chatUsers = await user.getUsersForChat(chatId);

      await Future.forEach(chatUsers, (chatUser) async {
        await Future.delayed(Duration(seconds: 1));

        var platformUserPremiumStatus = await platform.getUserPremiumStatus(chatId, chatUser.id);

        if (chatUser.isPremium != platformUserPremiumStatus) {
          print('Updating premium status for ${chatUser.id}');

          await user.updatePremiumStatus(chatUser.id, platformUserPremiumStatus);
        }
      });
    });
  }
}
