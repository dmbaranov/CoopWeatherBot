import './events/accordion_poll_events.dart';
import './event_bus.dart';
import './chat.dart';
import './user.dart' show BotUser;

enum AccordionVoteOption { yes, no, maybe }

class AccordionPoll {
  final EventBus eventBus;
  final Chat chat;
  late BotUser _fromUser;
  late BotUser _toUser;
  late String _chatId;
  final int _pollTime = 180;
  bool _isVoteActive = false;
  Map<AccordionVoteOption, int> _voteResult = {};

  AccordionPoll({required this.eventBus, required this.chat});

  get pollTime => _pollTime;

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

    var recordedOptions = _voteResult;

    _stopPoll();

    var voteResultKeys = recordedOptions.keys.toList();

    if (voteResultKeys.isEmpty) {
      return 'accordion.results.no_results';
    }

    var winnerOption =
        recordedOptions.entries.toList().reduce((currentVote, nextVote) => currentVote.value > nextVote.value ? currentVote : nextVote).key;

    switch (winnerOption) {
      case AccordionVoteOption.yes:
        eventBus.fire(PollCompletedYes(fromUser: _fromUser, toUser: _toUser, chatId: _chatId));
        return 'accordion.results.yes';

      case AccordionVoteOption.no:
        eventBus.fire(PollCompletedNo(fromUser: _fromUser, toUser: _toUser, chatId: _chatId));
        return 'accordion.results.no';

      case AccordionVoteOption.maybe:
        return 'accordion.results.maybe';
    }
  }

  void _stopPoll() {
    _isVoteActive = false;
    _voteResult = {};
  }
}
