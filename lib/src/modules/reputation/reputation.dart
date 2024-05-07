import 'dart:async';
import 'package:cron/cron.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/event_bus.dart';
import 'package:weather/src/core/repositories/reputation_repository.dart';
import 'package:weather/src/events/accordion_poll_events.dart';
import 'package:weather/src/globals/chat_reputation_data.dart';
import 'package:weather/src/globals/single_reputation_data.dart';
import 'package:weather/src/globals/module_exception.dart';
import 'package:weather/src/utils/logger.dart';

enum ReputationChangeOption { increase, decrease }

class ReputationException extends ModuleException {
  ReputationException(super.cause);
}

const numberOfVoteOptions = 3;

class Reputation {
  final EventBus _eventBus;
  final ReputationRepository _reputationDb;
  final Logger _logger;

  Reputation()
      : _reputationDb = getIt<ReputationRepository>(),
        _eventBus = getIt<EventBus>(),
        _logger = getIt<Logger>();

  void initialize() {
    _startResetVotesJob();
    _listenToAccordionPolls();
  }

  Future<bool> updateReputation(
      {required String chatId, required ReputationChangeOption change, String? fromUserId, String? toUserId}) async {
    var fromUser = await _reputationDb.getSingleReputationData(chatId, fromUserId ?? '');
    var toUser = await _reputationDb.getSingleReputationData(chatId, toUserId ?? '');

    if (fromUser == null || toUser == null) {
      throw ReputationException('reputation.change.user_not_found');
    }

    if (fromUserId == toUserId) {
      throw ReputationException('reputation.change.self_update');
    }

    if (change == ReputationChangeOption.increase && !_canIncreaseReputationCheck(fromUser)) {
      throw ReputationException('reputation.change.not_enough_options');
    } else if (change == ReputationChangeOption.decrease && !_canDecreaseReputationCheck(fromUser)) {
      throw ReputationException('reputation.change.not_enough_options');
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
      throw ReputationException('general.something_went_wrong');
    }

    var reputationUpdated = await _updateReputation(chatId, toUserId!, reputationValue);

    if (!reputationUpdated) {
      throw ReputationException('general.something_went_wrong');
    }

    return true;
  }

  Future<bool> createReputationData(String chatId, String userId) async {
    // TODO: add 6 options for premium users
    var result = await _reputationDb.createReputationData(chatId, userId, numberOfVoteOptions);

    return result == 1;
  }

  Future<List<ChatReputationData>> getReputationData(String chatId) async {
    var reputation = await _reputationDb.getReputationForChat(chatId);

    return reputation;
  }

  Future<bool> _forceUpdateReputation(String chatId, String userId, int reputation) async {
    // This method is intended to be used only by the system
    var existingUser = await _reputationDb.getSingleReputationData(chatId, userId);

    if (existingUser == null) {
      return false;
    }

    var result = await _reputationDb.updateReputation(chatId, userId, reputation);

    return result == 1;
  }

  Future<bool> _updateReputation(String chatId, String userId, int reputation) async {
    var result = await _reputationDb.updateReputation(chatId, userId, reputation);

    return result == 1;
  }

  Future<bool> _updateChangeOptions(String chatId, String userId, int increaseOptions, int decreaseOptions) async {
    var result = await _reputationDb.updateChangeOptions(chatId, userId, increaseOptions, decreaseOptions);

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
      var result = await _reputationDb.resetChangeOptions(numberOfVoteOptions);

      if (result == 0) {
        _logger.w('Something went wrong with resetting reputation change options');
      } else {
        _logger.i('Reset reputation change options for $result rows');
      }
    });
  }

  void _listenToAccordionPolls() {
    _eventBus.on<PollCompletedYes>().listen((event) => _updateAccordionPollReputation(event.chatId, event.toUser.id));
    _eventBus.on<PollCompletedNo>().listen((event) => _updateAccordionPollReputation(event.chatId, event.fromUser.id));
  }

  void _updateAccordionPollReputation(String chatId, String userId) async {
    var userReputationData = await _reputationDb.getSingleReputationData(chatId, userId);

    if (userReputationData != null) {
      _forceUpdateReputation(chatId, userId, userReputationData.reputation - 1);
    }
  }
}
