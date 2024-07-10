import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/globals/poll.dart';
import 'package:weather/src/globals/accordion_vote_option.dart';
import 'package:weather/src/injector/injection.dart';

typedef VoteOptionData = ({AccordionVoteOption option, String text, int votes});

const _accordionPollDuration = Duration(seconds: 180);
const List<VoteOptionData> _accordionOptions = [
  (option: AccordionVoteOption.yes, text: 'accordion.options.yes', votes: 0),
  (option: AccordionVoteOption.no, text: 'accordion.options.no', votes: 0),
  (option: AccordionVoteOption.maybe, text: 'accordion.options.maybe', votes: 0),
];

class AccordionPoll2 extends Poll {
  final Swearwords _sw;
  final Map<String, VoteOptionData> _pollVotes = {};
  bool _pollActive = false;
  Duration _duration = Duration(seconds: 0);
  String? _fromUserId;
  String? _toUserId;

  AccordionPoll2({required super.title, super.description}) : _sw = getIt<Swearwords>();

  @override
  String? get result => _winOption.value.votes > 0 ? _winOption.key : null;

  @override
  Duration get duration => _duration;

  @override
  List<String> get options => _pollVotes.keys.toList();

  MapEntry<String, VoteOptionData> get _winOption => _pollVotes.entries
      .toList()
      .reduce((currentOption, nextOption) => currentOption.value.votes > nextOption.value.votes ? currentOption : nextOption);

  Future<Poll> startPoll({required String chatId, required String fromUserId, required String toUserId}) async {
    if (_pollActive) {
      // TODO: add other exceptions
      throw Exception('Poll active');
    }

    var translatedOptions = _getTranslatedOptions(chatId, _accordionOptions);
    translatedOptions.forEach((option) {
      _pollVotes[option.text] = option;
    });

    _pollActive = true;
    _duration = _accordionPollDuration;
    _fromUserId = fromUserId;
    _toUserId = toUserId;

    return this;
  }

  @override
  void updatePollOptionCount(String option, [int? newOptionResult]) {
    var pollOption = _pollVotes[option];

    if (pollOption == null) {
      throw Exception("Option $option does not exist in this poll");
    }

    _pollVotes[option] = (option: pollOption.option, text: pollOption.text, votes: newOptionResult ?? pollOption.votes + 1);
  }

  List<VoteOptionData> _getTranslatedOptions(String chatId, List<VoteOptionData> voteOptions) {
    return voteOptions.map((option) => (option: option.option, text: _sw.getText(chatId, option.text), votes: option.votes)).toList();
  }
}
