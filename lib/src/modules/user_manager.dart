import 'dart:async';
import 'package:cron/cron.dart';
import 'database-manager/database_manager.dart';

class UMUser {
  final String id;
  final bool isPremium;
  final bool deleted;
  final bool banned;
  final bool moderator;

  String name;

  UMUser(
      {required this.id,
      required this.name,
      required this.isPremium,
      required this.deleted,
      required this.banned,
      required this.moderator}) {
    var markedAsPremium = name.contains('⭐');

    if (isPremium && !markedAsPremium) {
      name += ' ⭐';
    } else if (!isPremium && markedAsPremium) {
      name = name.replaceAll(' ⭐', '');
    }
  }
}

class UserManager {
  final DatabaseManager dbManager;

  late StreamController<int> _userManagerStreamController;
  ScheduledTask? _userManagerCronTask;

  UserManager({required this.dbManager});

  Stream<int> get userManagerStream => _userManagerStreamController.stream;

  void initialize() {
    _userManagerStreamController = StreamController<int>.broadcast();
    _updateUserManagerStream();
  }

  Future<List<UMUser>> getUsersForChat(String chatId) async {
    var users = await dbManager.user.getAllUsersForChat(chatId);

    return users
        .map((dbUser) => UMUser(
            id: dbUser.id,
            name: dbUser.name,
            isPremium: dbUser.isPremium,
            deleted: dbUser.deleted,
            banned: dbUser.banned,
            moderator: dbUser.moderator))
        .toList();
  }

  Future<bool> isValidUser(String chatId, String userId) async {
    var user = await dbManager.user.getSingleChatUser(chatId: chatId, userId: userId);

    return user != null;
  }

  Future<bool> addUser({required String userId, required String chatId, required String name, bool isPremium = false}) async {
    var creationResult = await dbManager.user.createUser(userId: userId, chatId: chatId, name: name, isPremium: isPremium);

    if (creationResult >= 1) {
      _userManagerStreamController.sink.add(0);

      return true;
    }

    return false;
  }

  Future<bool> removeUser(String chatId, String userId) async {
    var deletionResult = await dbManager.user.deleteUser(chatId, userId);

    if (deletionResult == 1) {
      _userManagerStreamController.sink.add(0);

      return true;
    }

    return false;
  }

  void _updateUserManagerStream() {
    _userManagerCronTask?.cancel();

    _userManagerCronTask = Cron().schedule(Schedule.parse('0 0 * * *'), () {
      _userManagerStreamController.sink.add(0);
    });
  }
}
