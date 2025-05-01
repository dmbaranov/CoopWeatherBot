import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/utils/logger.dart';
import 'user.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class UserManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final User _user;
  final Swearwords _sw;
  final Logger _logger;

  UserManager(this.platform, this.modulesMediator)
      : _user = User(),
        _logger = getIt<Logger>(),
        _sw = getIt<Swearwords>();

  @override
  User get module => _user;

  @override
  void initialize() {
    _user.initialize();
    _subscribeToUserUpdates();
  }

  void addUser(MessageEvent event) async {
    if (!otherUserCheck(platform, event)) return;

    var chatId = event.chatId;
    var (id: userId, name: username, isPremium: isPremium, isBot: _) = event.otherUser!;
    var result = await _user.addUser(userId: userId, chatId: chatId, name: username, isPremium: isPremium);
    var successfulMessage = _sw.getText(chatId, 'user.user_added');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void removeUser(MessageEvent event) async {
    if (!otherUserCheck(platform, event)) return;

    var chatId = event.chatId;
    var result = await _user.removeUser(chatId, event.otherUser!.id);
    var successfulMessage = _sw.getText(chatId, 'user.user_removed');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void _subscribeToUserUpdates() {
    _user.userManagerStream.listen((_) {
      _updateUsersPremiumStatus();
    });
  }

  Future<void> _updateUsersPremiumStatus() async {
    var allPlatformChatIds = await modulesMediator.chat.getAllChatIdsForPlatform(platform.chatPlatform);

    await Future.forEach(allPlatformChatIds, (chatId) async {
      var chatUsers = await _user.getUsersForChat(chatId);

      await Future.forEach(chatUsers, (chatUser) async {
        await Future.delayed(Duration(seconds: 1));

        var platformUserPremiumStatus = await platform.getUserPremiumStatus(chatId, chatUser.id);

        if (chatUser.isPremium != platformUserPremiumStatus) {
          _logger.i('Updating premium status for ${chatUser.id}');

          await _user.updatePremiumStatus(chatUser.id, platformUserPremiumStatus);
        }
      });
    });
  }
}
