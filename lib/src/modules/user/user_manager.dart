import 'package:weather/src/globals/message_event.dart';
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
