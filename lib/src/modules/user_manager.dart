import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:cron/cron.dart';

const String _pathToUsersFile = 'assets/users.json';

class UMUser {
  final String id;
  final String name;
  final bool isPremium;

  UMUser({required this.id, required this.name, this.isPremium = false});

  UMUser.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        isPremium = json['isPremium'] ?? false;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isPremium': isPremium};
}

// TODO: to update users, create a stream that would trigger a method from the class. In telegram, get chatMember by id and check his name, premium, etc. Trigger this function once a day
class UserManager {
  final File _usersFile = File(_pathToUsersFile);
  final List<UMUser> _users = [];
  late StreamController<int> _userManagerStreamController;
  ScheduledTask? _userManagerCronTask;

  List<UMUser> get users => _users;

  Stream<int> get userManagerStream => _userManagerStreamController.stream;

  Future<void> initialize() async {
    var rawUsersFromFile = await _usersFile.readAsString();
    List usersFromFile = json.decode(rawUsersFromFile);

    usersFromFile.forEach((rawUser) {
      _users.add(UMUser.fromJson(rawUser));
    });

    _userManagerStreamController = StreamController<int>.broadcast();
    _updateUserManagerStream();
  }

  Future<bool> addUser(UMUser userToAdd) async {
    var foundUser = _users.firstWhereOrNull((user) => user.id == userToAdd.id);

    if (foundUser != null) {
      return false;
    }

    _users.add(userToAdd);

    await _updateUsersFile();

    return true;
  }

  Future<bool> removeUser(String userIdToRemove) async {
    var foundUser = _users.firstWhereOrNull((user) => user.id == userIdToRemove);

    if (foundUser == null) {
      return false;
    }

    _users.removeWhere((user) => user.id == userIdToRemove);

    await _updateUsersFile();

    return true;
  }

  Future<void> _updateUsersFile() async {
    var usersJson = json.encode(_users.map((user) => user.toJson()).toList());

    await _usersFile.writeAsString(usersJson);
  }

  void _updateUserManagerStream() {
    _userManagerCronTask?.cancel();

    _userManagerCronTask = Cron().schedule(Schedule.parse('0 0 * * *'), () {
      _userManagerStreamController.sink.add(0);
    });
  }
}
