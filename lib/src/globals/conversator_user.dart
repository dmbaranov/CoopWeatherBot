class ConversatorUser {
  final String id;
  final int dailyRegularInvocations;
  final int totalRegularInvocations;
  final int dailyAdvancedInvocations;
  final int totalAdvancedInvocations;

  ConversatorUser(
      {required this.id,
      required this.dailyRegularInvocations,
      required this.totalRegularInvocations,
      required this.dailyAdvancedInvocations,
      required this.totalAdvancedInvocations});
}
