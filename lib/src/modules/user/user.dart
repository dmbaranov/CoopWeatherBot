import 'dart:async';
import 'package:cron/cron.dart';
import 'package:weather/src/core/messaging.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/repositories/bot_user_repository.dart';
import 'package:weather/src/globals/bot_user.dart';

class User {
  final BotUserRepository _userDb;
  final Messaging _messaging;

  late StreamController<int> _userManagerStreamController;
  ScheduledTask? _userManagerCronTask;

  User()
      : _userDb = getIt<BotUserRepository>(),
        _messaging = getIt<Messaging>();

  Stream<int> get userManagerStream => _userManagerStreamController.stream;

  void initialize() {
    _userManagerStreamController = StreamController<int>.broadcast();
    _updateUserManagerStream();
    _subscribeToMessagingEvents();
  }

  Future<BotUser?> getSingleUserForChat(String chatId, String userId) async {
    return _userDb.getSingleUserForChat(chatId, userId);
  }

  Future<List<BotUser>> getUsersForChat(String chatId) async {
    return _userDb.getAllUsersForChat(chatId);
  }

  Future<bool> addUser({required String userId, required String chatId, required String name, bool isPremium = false}) async {
    var creationResult = await _userDb.createUser(userId: userId, chatId: chatId, name: name, isPremium: isPremium);

    if (creationResult >= 1) {
      _userManagerStreamController.sink.add(0);

      return true;
    }

    return false;
  }

  Future<bool> removeUser(String chatId, String userId) async {
    var deletionResult = await _userDb.deleteUser(chatId, userId);

    if (deletionResult == 1) {
      _userManagerStreamController.sink.add(0);

      return true;
    }

    return false;
  }

  Future<bool> updatePremiumStatus(String userId, bool isPremium) async {
    var updateResult = await _userDb.updatePremiumStatus(userId, isPremium);

    return updateResult == 1;
  }

  void _updateUserManagerStream() {
    _userManagerCronTask?.cancel();

    _userManagerCronTask = Cron().schedule(Schedule.parse('0 0 * * *'), () {
      _userManagerStreamController.sink.add(0);
    });
  }

  void _subscribeToMessagingEvents() async {
    var queue = await _messaging.subscribeToQueue('member-updated');

    queue.listen((event) {
      print('handling ${event.payloadAsJson}');
    });
  }
}
