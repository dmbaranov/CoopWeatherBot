import 'dart:async';
import 'package:cron/cron.dart';
import 'database-manager/database_manager.dart';

class UMUser {
  final String id;
  final bool isPremium;
  final String chatId;
  String name;

  UMUser({required this.id, required this.name, required this.chatId, this.isPremium = false}) {
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

    return users.map((dbUser) => UMUser(id: dbUser.id, name: dbUser.name, chatId: dbUser.chatId, isPremium: dbUser.isPremium)).toList();
  }

  Future<bool> addUser({required String id, required String chatId, required String name, bool isPremium = false}) async {
    var creationResult = await dbManager.user.createUser(id: id, chatId: chatId, name: name, isPremium: isPremium);

    if (creationResult == 1) {
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
