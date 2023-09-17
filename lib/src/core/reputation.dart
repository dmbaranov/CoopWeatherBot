import 'dart:async';
import 'package:cron/cron.dart';
import 'events/accordion_poll_events.dart';
import 'database.dart';
import 'event_bus.dart';

enum ReputationChangeOption { increase, decrease }

enum ReputationChangeResult { increaseSuccess, decreaseSuccess, userNotFound, selfUpdate, notEnoughOptions, systemError }

const numberOfVoteOptions = 3;

class SingleReputationData {
  final String id;
  final int reputation;
  final int increaseOptionsLeft;
  final int decreaseOptionsLeft;

  SingleReputationData({required this.id, required this.reputation, required this.increaseOptionsLeft, required this.decreaseOptionsLeft});
}

class ChatReputationData {
  final String name;
  final int reputation;

  ChatReputationData({required this.name, required this.reputation});
}

class Reputation {
  final Database db;
  final EventBus eventBus;

  Reputation({required this.db, required this.eventBus});

  void initialize() {
    _startResetVotesJob();
    _listenToAccordionPolls();
  }

  Future<ReputationChangeResult> updateReputation(
      {required String chatId, required ReputationChangeOption change, String? fromUserId, String? toUserId}) async {
    var fromUser = await db.reputation.getSingleReputationData(chatId, fromUserId ?? '');
    var toUser = await db.reputation.getSingleReputationData(chatId, toUserId ?? '');

    if (fromUser == null || toUser == null) {
      return ReputationChangeResult.userNotFound;
    }

    if (fromUserId == toUserId) {
      return ReputationChangeResult.selfUpdate;
    }

    if (change == ReputationChangeOption.increase && !_canIncreaseReputationCheck(fromUser)) {
      return ReputationChangeResult.notEnoughOptions;
    } else if (change == ReputationChangeOption.decrease && !_canDecreaseReputationCheck(fromUser)) {
      return ReputationChangeResult.notEnoughOptions;
    }

    var reputationValue = toUser.reputation;
    var increaseOptions = fromUser.increaseOptionsLeft;
    var decreaseOptions = fromUser.decreaseOptionsLeft;

    if (change == ReputationChangeOption.increase) {
      reputationValue += 1;
      increaseOptions -= 1;
    } else {
      reputationValue -= 1;
      decreaseOptions -= 1;
    }

    var optionsUpdated = await _updateChangeOptions(chatId, fromUserId!, increaseOptions, decreaseOptions);

    if (!optionsUpdated) {
      return ReputationChangeResult.systemError;
    }

    var reputationUpdated = await _updateReputation(chatId, toUserId!, reputationValue);

    if (!reputationUpdated) {
      return ReputationChangeResult.systemError;
    }

    return change == ReputationChangeOption.increase ? ReputationChangeResult.increaseSuccess : ReputationChangeResult.decreaseSuccess;
  }

  Future<bool> createReputationData(String chatId, String userId) async {
    // TODO: add 6 options for premium users
    var result = await db.reputation.createReputationData(chatId, userId, numberOfVoteOptions);

    return result == 1;
  }

  Future<List<ChatReputationData>> getReputationData(String chatId) async {
    var reputation = await db.reputation.getReputationForChat(chatId);

    return reputation;
  }

  Future<bool> _forceUpdateReputation(String chatId, String userId, int reputation) async {
    // This method is intended to be used only by the system
    var existingUser = await db.reputation.getSingleReputationData(chatId, userId);

    if (existingUser == null) {
      return false;
    }

    var result = await db.reputation.updateReputation(chatId, userId, reputation);

    return result == 1;
  }

  Future<bool> _updateReputation(String chatId, String userId, int reputation) async {
    var result = await db.reputation.updateReputation(chatId, userId, reputation);

    return result == 1;
  }

  Future<bool> _updateChangeOptions(String chatId, String userId, int increaseOptions, int decreaseOptions) async {
    var result = await db.reputation.updateChangeOptions(chatId, userId, increaseOptions, decreaseOptions);

    return result == 1;
  }

  bool _canIncreaseReputationCheck(SingleReputationData user) {
    return user.increaseOptionsLeft > 0;
  }

  bool _canDecreaseReputationCheck(SingleReputationData user) {
    return user.decreaseOptionsLeft > 0;
  }

  void _startResetVotesJob() {
    Cron().schedule(Schedule.parse('0 0 * * *'), () async {
      var result = await db.reputation.resetChangeOptions(numberOfVoteOptions);

      if (result == 0) {
        print('Something went wrong with resetting reputation change options');
      } else {
        print('Reset reputation change options for $result rows');
      }
    });
  }

  void _listenToAccordionPolls() {
    eventBus.on<PollCompletedYes>().listen((event) => _updateAccordionPollReputation(event.chatId, event.toUser.id));
    eventBus.on<PollCompletedNo>().listen((event) => _updateAccordionPollReputation(event.chatId, event.fromUser.id));
  }

  void _updateAccordionPollReputation(String chatId, String userId) async {
    var userReputationData = await db.reputation.getSingleReputationData(chatId, userId);

    if (userReputationData != null) {
      _forceUpdateReputation(chatId, userId, userReputationData.reputation - 1);
    }
  }
}
