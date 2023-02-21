import 'swearwords_manager.dart';

enum VoteOption { yes, no, maybe }

class AccordionPoll {
  final SwearwordsManager sm;
  bool _isVoteActive = false;
  String? _userId;
  Map<VoteOption, int> _voteResult = {};

  AccordionPoll({required this.sm});

  bool get isVoteActive => _isVoteActive;

  set voteResult(Map<VoteOption, int> updatedVoteResult) {
    _voteResult = updatedVoteResult;
  }

  set userId(String userId) {
    _userId = userId;
  }

  void startPoll(String userId) {
    _isVoteActive = true;
    _userId = userId;
  }

  void _stopPoll() {
    _isVoteActive = false;
    _userId = null;
    _voteResult = {};
  }

  String endVoteAndGetResults() {
    var recordedOptions = _voteResult;

    _stopPoll();

    var voteResultKeys = recordedOptions.keys.toList();

    if (voteResultKeys.isEmpty) {
      return sm.get('accordion_no_results');
    }

    var messages = {
      VoteOption.yes: sm.get('accordion_yes_voted'),
      VoteOption.no: sm.get('accordion_no_voted'),
      VoteOption.maybe: sm.get('accordion_maybe_voted')
    };

    var winnerOption =
        recordedOptions.entries.toList().reduce((currentVote, nextVote) => currentVote.value > nextVote.value ? currentVote : nextVote).key;

    return messages[winnerOption]!;
  }
}
