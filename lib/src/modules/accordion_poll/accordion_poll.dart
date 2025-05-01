import 'package:weather/src/core/event_bus.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/events/accordion_poll_events.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/globals/module_exception.dart';
import 'package:weather/src/globals/poll.dart';
import 'package:weather/src/utils/logger.dart';

enum AccordionVoteOption { yes, no, maybe }

typedef VoteOptionData = ({AccordionVoteOption option, String text, int votes});

class AccordionPollException extends ModuleException {
  AccordionPollException(super.cause);
}

const Duration _accordionPollDuration = Duration(seconds: 180);
const List<VoteOptionData> _accordionOptions = [
  (option: AccordionVoteOption.yes, text: 'accordion.options.yes', votes: 0),
  (option: AccordionVoteOption.no, text: 'accordion.options.no', votes: 0),
  (option: AccordionVoteOption.maybe, text: 'accordion.options.maybe', votes: 0),
];

class AccordionPoll extends Poll {
  final Swearwords _sw;
  final EventBus _eventBus;
  final Logger _logger;
  final Map<String, VoteOptionData> _pollVotes = {};
  bool _pollActive = false;
  Duration _duration = Duration(seconds: 0);
  String? _fromUserId;
  String? _toUserId;
  String? _chatId;

  AccordionPoll({required super.title, super.description})
      : _sw = getIt<Swearwords>(),
        _eventBus = getIt<EventBus>(),
        _logger = getIt<Logger>();

  @override
  String get result => _winOption.value.votes > 0 ? 'accordion.results.${_winOption.value.option.name}' : 'accordion.results.no_results';

  @override
  Duration get duration => _duration;

  @override
  List<String> get options => _pollVotes.keys.toList();

  MapEntry<String, VoteOptionData> get _winOption => _pollVotes.entries
      .toList()
      .reduce((currentOption, nextOption) => currentOption.value.votes > nextOption.value.votes ? currentOption : nextOption);

  Future<Poll> startPoll({required String chatId, required String fromUserId, required String toUserId}) async {
    if (_pollActive) {
      throw AccordionPollException('accordion.other.accordion_vote_in_progress');
    }

    var translatedOptions = _getTranslatedOptions(chatId, _accordionOptions);
    translatedOptions.forEach((option) {
      _pollVotes[option.text] = option;
    });

    _pollActive = true;
    _duration = _accordionPollDuration;
    _fromUserId = fromUserId;
    _toUserId = toUserId;
    _chatId = chatId;

    return this;
  }

  @override
  void updatePollOptionCount(String option, [int? newOptionResult]) {
    var pollOption = _pollVotes[option];

    if (pollOption == null) {
      _logger.e("Option $option does not exist in this poll");
      return;
    }

    _pollVotes[option] = (option: pollOption.option, text: pollOption.text, votes: newOptionResult ?? pollOption.votes + 1);
  }

  @override
  void endPoll() {
    switch (_winOption.value.option) {
      case AccordionVoteOption.yes:
        _eventBus.fire(PollCompletedYes(fromUserId: _fromUserId!, toUserId: _toUserId!, chatId: _chatId!));
        break;
      case AccordionVoteOption.no:
        _eventBus.fire(PollCompletedNo(fromUserId: _fromUserId!, toUserId: _toUserId!, chatId: _chatId!));
        break;
      case AccordionVoteOption.maybe:
        break;
    }
  }

  List<VoteOptionData> _getTranslatedOptions(String chatId, List<VoteOptionData> voteOptions) {
    return voteOptions.map((option) => (option: option.option, text: _sw.getText(chatId, option.text), votes: option.votes)).toList();
  }
}
