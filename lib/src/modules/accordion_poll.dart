enum AccordionVoteOption { yes, no, maybe }

enum AccordionVoteResults { yes, no, maybe, noResults }

class AccordionPoll {
  bool _isVoteActive = false;
  String? _userId;
  Map<AccordionVoteOption, int> _voteResult = {};

  bool get isVoteActive => _isVoteActive;

  set voteResult(Map<AccordionVoteOption, int> updatedVoteResult) {
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

    return messages[winnerOption]!;
  }
}
