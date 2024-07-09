import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/globals/poll.dart';
import 'package:weather/src/globals/accordion_vote_option.dart';
import 'package:weather/src/injector/injection.dart';

typedef VoteOptionData = (AccordionVoteOption, String);

const _accordionPollDuration = Duration(seconds: 180);
const _accordionOptions = [
  (AccordionVoteOption.yes, 'accordion.options.yes'),
  (AccordionVoteOption.no, 'accordion.options.no'),
  (AccordionVoteOption.maybe, 'accordion.options.maybe'),
];

class AccordionPoll2 extends Poll {
  final Swearwords _sw;
  bool _pollActive = false;
  Map<String, (AccordionVoteOption, int)> _pollResults = {};
  Duration _duration = Duration(seconds: 0);
  String? _fromUserId;
  String? _toUserId;

  AccordionPoll2({required super.title, super.description}) : _sw = getIt<Swearwords>();

  @override
  String? get result => _winOption.value.$2 > 0 ? _winOption.key : null;

  @override
  Duration get duration => _duration;

  @override
  get options => _pollResults.keys.toList();

  MapEntry<String, (AccordionVoteOption, int)> get _winOption => _pollResults.entries
      .toList()
      .reduce((currentOption, nextOption) => currentOption.value.$2 > nextOption.value.$2 ? currentOption : nextOption);

  Future<Poll> startPoll({required String chatId, required String fromUserId, required String toUserId}) async {
    if (_pollActive) {
      // TODO: add other exceptions
      throw Exception('Poll active');
    }

    var translatedOptions = _getTranslatedOptions(chatId, _accordionOptions);
    translatedOptions.forEach((option) {
      _pollResults[option.$2] = (option.$1, 0);
    });

    _pollActive = true;
    _duration = _accordionPollDuration;
    _fromUserId = fromUserId;
    _toUserId = toUserId;

    return this;
  }

  @override
  void endPoll() {
    print('Emitting option: ${_winOption.value.$1}');

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

    _pollResults[option] = (pollOption.$1, newOptionResult ?? pollOption.$2 + 1);
  }

  List<VoteOptionData> _getTranslatedOptions(String chatId, List<VoteOptionData> voteOptions) {
    return voteOptions.map((option) => (option.$1, _sw.getText(chatId, option.$2))).toList();
  }
}
