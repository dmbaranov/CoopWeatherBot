import 'dart:async';
import 'package:collection/collection.dart';
import 'package:cron/cron.dart';
import 'database-manager/datanase_manager.dart';

class UMUser {
  final String id;
  final bool isPremium;
  String? chatId;
  String name;

  UMUser({required this.id, required this.name, this.chatId, this.isPremium = false}) {
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
  final List<UMUser> _users = [];
  late StreamController<int> _userManagerStreamController;
  ScheduledTask? _userManagerCronTask;

  UserManager({required this.dbManager});

  List<UMUser> get users => _users;

  Stream<int> get userManagerStream => _userManagerStreamController.stream;

  Future<void> initialize() async {
    var dbUsers = await dbManager.user.getAllUsers();

    dbUsers.forEach((user) => _users.add(UMUser(id: user.id, name: user.name, isPremium: user.isPremium)));

    _userManagerStreamController = StreamController<int>.broadcast();
    _updateUserManagerStream();
  }

  Future<bool> addUser({required String id, required String chatId, required String name, bool isPremium = false}) async {
    var foundUser = _users.firstWhereOrNull((user) => user.id == id);

    if (foundUser != null) {
      return false;
    }

    _users.add(UMUser(id: id, chatId: chatId, name: name, isPremium: isPremium));
    _userManagerStreamController.sink.add(0);

    await dbManager.user.createUser(id: id, chatId: chatId, name: name, isPremium: isPremium);

    return true;
  }

  Future<bool> removeUser(String userIdToRemove) async {
    var foundUser = _users.firstWhereOrNull((user) => user.id == userIdToRemove);

    if (foundUser == null) {
      return false;
    }

    _users.removeWhere((user) => user.id == userIdToRemove);
    _userManagerStreamController.sink.add(0);

    await dbManager.user.deleteUser(userIdToRemove);

    return true;
  }

  void _updateUserManagerStream() {
    _userManagerCronTask?.cancel();

    _userManagerCronTask = Cron().schedule(Schedule.parse('0 0 * * *'), () {
      _userManagerStreamController.sink.add(0);
    });
  }
}
