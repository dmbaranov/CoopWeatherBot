abstract class Poll {
  final String title;
  String? description;

  Poll({required this.title, this.description});

  String get result;

  List<String> get options;

  Duration get duration;

  void endPoll();

  void updatePollOptionCount(String option, [int? newOptionResult]);
}
