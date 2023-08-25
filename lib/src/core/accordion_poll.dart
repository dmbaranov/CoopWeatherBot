import './events/accordion_poll_events.dart';
import './event_bus.dart';
import './user.dart' show BotUser;

enum AccordionVoteOption { yes, no, maybe }

enum AccordionVoteResults { yes, no, maybe, noResults }

class AccordionPoll {
  final EventBus eventBus;

  late BotUser _fromUser;
  late BotUser _toUser;
  late String _chatId;
  bool _isVoteActive = false;
  Map<AccordionVoteOption, int> _voteResult = {};

  AccordionPoll({required this.eventBus});

  bool get isVoteActive => _isVoteActive;

  set voteResult(Map<AccordionVoteOption, int> updatedVoteResult) {
    if (_isVoteActive) {
      _voteResult = updatedVoteResult;
    }
  }

  void startPoll(BotUser fromUser, BotUser toUser, String chatId) {
    _isVoteActive = true;
    _fromUser = fromUser;
    _toUser = toUser;
    _chatId = chatId;
  }

  AccordionVoteResults endVoteAndGetResults() {
    var recordedOptions = _voteResult;

    _stopPoll();

    var voteResultKeys = recordedOptions.keys.toList();

    if (voteResultKeys.isEmpty) {
      return AccordionVoteResults.noResults;
    }

    var messages = {
      AccordionVoteOption.yes: AccordionVoteResults.yes,
      AccordionVoteOption.no: AccordionVoteResults.no,
      AccordionVoteOption.maybe: AccordionVoteResults.maybe
    };

    var winnerOption =
        recordedOptions.entries.toList().reduce((currentVote, nextVote) => currentVote.value > nextVote.value ? currentVote : nextVote).key;

    if (winnerOption == AccordionVoteOption.yes) {
      eventBus.fire(PollCompletedYes(fromUser: _fromUser, toUser: _toUser, chatId: _chatId));
    } else if (winnerOption == AccordionVoteOption.no) {
      eventBus.fire(PollCompletedNo(fromUser: _fromUser, toUser: _toUser, chatId: _chatId));
    }

    return messages[winnerOption]!;
  }

  void _stopPoll() {
    _isVoteActive = false;
    _voteResult = {};
  }
}
