import 'dart:io';
import 'dart:convert';
import 'package:collection/collection.dart';

const String _pathToUsersFile = 'assets/users.json';

class User {
  final String id;
  final String name;
  bool isPremium = false;

  User({required this.id, required this.name});

  User.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        isPremium = json['isPremium'] ?? false;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'isPremium': isPremium};
}

class UserManager {
  final File _usersFile = File(_pathToUsersFile);
  final List<User> _users = [];

  List<User> get users => _users;

  Future<void> initialize() async {
    var rawUsersFromFile = await _usersFile.readAsString();
    List usersFromFile = json.decode(rawUsersFromFile);

    usersFromFile.forEach((rawUser) {
      _users.add(User.fromJson(rawUser));
    });
  }

  Future<bool> addUser(User userToAdd) async {
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
    var usersJson = json.encode(_users.map((user) => user.toJson()).toString());

    await _usersFile.writeAsString(usersJson);
  }
}
