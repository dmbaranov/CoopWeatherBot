import 'package:weather/src/globals/poll.dart';

class AccordionPoll2 extends Poll {
  bool _pollActive = false;
  Map<String, int> _pollResults = {};
  Duration _duration = Duration(seconds: 0);
  String? _fromUserId;
  String? _toUserId;

  AccordionPoll2({required super.title, super.description});

  @override
  String? get result {
    var winOption = _pollResults.entries
        .toList()
        .reduce((currentOption, nextOption) => currentOption.value > nextOption.value ? currentOption : nextOption);

    if (winOption.value > 0) {
      return winOption.key;
    }

    return null;
  }

  @override
  Duration get duration => _duration;

  @override
  get options => _pollResults.keys.toList();

  Future<Poll> startPoll(
      {required Duration duration, required List<String> options, required String fromUserId, required String toUserId}) async {
    if (_pollActive) {
      // TODO: add other exceptions
      throw Exception('Poll active');
    }

    options.forEach((option) {
      _pollResults[option] = 0;
    });

    _pollActive = true;
    _duration = duration;
    _fromUserId = fromUserId;
    _toUserId = toUserId;

    return this;
  }

  @override
  void endPoll() {
    _pollActive = false;
    _pollResults = {};
    _fromUserId = null;
    _toUserId = null;
  }

  @override
  void updatePollOptionCount(String option, [int? newOptionResult]) {
    var pollOption = _pollResults[option];

    if (pollOption == null) {
      throw Exception("Option $option does not exist in this poll");
    }

    _pollResults[option] = newOptionResult ?? pollOption + 1;
  }
}
