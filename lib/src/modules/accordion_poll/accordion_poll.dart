import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/event_bus.dart';
import 'package:weather/src/events/accordion_poll_events.dart';
import 'package:weather/src/globals/accordion_vote_option.dart';
import 'package:weather/src/globals/bot_user.dart';
import 'package:weather/src/modules/chat/chat.dart';

class AccordionPoll {
  final Chat chat;
  final int pollTime;
  final EventBus _eventBus;
  late BotUser _fromUser;
  late BotUser _toUser;
  late String _chatId;
  bool _isVoteActive = false;
  Map<AccordionVoteOption, int> _voteResult = {};

  AccordionPoll({required this.chat, this.pollTime = 180}) : _eventBus = getIt<EventBus>();

  get pollOptions => [
        chat.getText(_chatId, 'accordion.options.yes'),
        chat.getText(_chatId, 'accordion.options.no'),
        chat.getText(_chatId, 'accordion.options.maybe')
      ];

  String? startPoll({
    required String chatId,
    required bool isBot,
    BotUser? fromUser,
    BotUser? toUser,
  }) {
    // TODO: change to Enum like reputation
    if (_isVoteActive) {
      return 'accordion.other.accordion_vote_in_progress';
    } else if (toUser == null) {
      return 'accordion.other.message_not_chosen';
    } else if (isBot) {
      return 'accordion.other.bot_vote_attempt';
    } else if (fromUser == null) {
      return 'general.something_went_wrong';
    }

    _isVoteActive = true;
    _fromUser = fromUser;
    _toUser = toUser;
    _chatId = chatId;

    return null;
  }

  void updatePollResults(Map<AccordionVoteOption, int> results) {
    if (_isVoteActive) {
      _voteResult = results;
    }
  }

  Future<String> endVoteAndGetResults() async {
    await Future.delayed(Duration(seconds: pollTime));

    var voteResultKeys = _voteResult.keys.toList();

    if (voteResultKeys.isEmpty) {
      return 'accordion.results.no_results';
    }

    var winnerOption =
        _voteResult.entries.toList().reduce((currentVote, nextVote) => currentVote.value > nextVote.value ? currentVote : nextVote).key;

    String winningTranslation;

    switch (winnerOption) {
      case AccordionVoteOption.yes:
        _eventBus.fire(PollCompletedYes(fromUser: _fromUser, toUser: _toUser, chatId: _chatId));
        winningTranslation = 'accordion.results.yes';
        break;

      case AccordionVoteOption.no:
        _eventBus.fire(PollCompletedNo(fromUser: _fromUser, toUser: _toUser, chatId: _chatId));
        winningTranslation = 'accordion.results.no';
        break;

      case AccordionVoteOption.maybe:
        winningTranslation = 'accordion.results.maybe';
        break;
    }

    _stopPoll();

    return winningTranslation;
  }

  void _stopPoll() {
    var emptyUser = BotUser(id: '0', name: '', isPremium: false, deleted: false, banned: false, moderator: false);

    _isVoteActive = false;
    _voteResult = {};
    _fromUser = emptyUser;
    _toUser = emptyUser;
    _chatId = '';
  }
}
