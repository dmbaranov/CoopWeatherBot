abstract class Poll {
  final String title;
  String? description;

  Poll({required this.title, this.description});

  String? get result;

  List<String> get options;

  Duration get duration;

  bool startPoll({required Duration duration, required List<String> options});

  void endPoll();

  void updatePollOptionCount(String option, [int? newOptionResult]);
}
