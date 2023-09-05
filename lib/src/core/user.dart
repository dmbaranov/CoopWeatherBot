import 'dart:async';
import 'package:cron/cron.dart';
import 'database.dart';

class BotUser {
  final String id;
  final bool isPremium;
  final bool deleted;
  final bool banned;
  final bool moderator;

  String name;

  BotUser(
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

class User {
  final Database db;

  late StreamController<int> _userManagerStreamController;
  ScheduledTask? _userManagerCronTask;

  User({required this.db});

  Stream<int> get userManagerStream => _userManagerStreamController.stream;

  void initialize() {
    _userManagerStreamController = StreamController<int>.broadcast();
    _updateUserManagerStream();
  }

  Future<BotUser?> getSingleUserForChat(String chatId, String userId) async {
    var user = await db.user.getSingleUserForChat(chatId, userId);

    if (user != null) {
      return BotUser(
          id: user.id, name: user.name, isPremium: user.isPremium, deleted: user.deleted, banned: user.banned, moderator: user.moderator);
    }

    return null;
  }

  Future<List<BotUser>> getUsersForChat(String chatId) async {
    var users = await db.user.getAllUsersForChat(chatId);

    return users
        .map((dbUser) => BotUser(
            id: dbUser.id,
            name: dbUser.name,
            isPremium: dbUser.isPremium,
            deleted: dbUser.deleted,
            banned: dbUser.banned,
            moderator: dbUser.moderator))
        .toList();
  }

  Future<bool> addUser({required String userId, required String chatId, required String name, bool isPremium = false}) async {
    var creationResult = await db.user.createUser(userId: userId, chatId: chatId, name: name, isPremium: isPremium);

    if (creationResult >= 1) {
      _userManagerStreamController.sink.add(0);

      return true;
    }

    return false;
  }

  Future<bool> removeUser(String chatId, String userId) async {
    var deletionResult = await db.user.deleteUser(chatId, userId);

    if (deletionResult == 1) {
      _userManagerStreamController.sink.add(0);

      return true;
    }

    return false;
  }

  Future<bool> updatePremiumStatus(String userId, bool isPremium) async {
    var updateResult = await db.user.updatePremiumStatus(userId, isPremium);

    return updateResult == 1;
  }

  void _updateUserManagerStream() {
    _userManagerCronTask?.cancel();

    _userManagerCronTask = Cron().schedule(Schedule.parse('0 0 * * *'), () {
      _userManagerStreamController.sink.add(0);
    });
  }
}
