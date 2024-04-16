class BotUser {
  final String id;
  final bool isPremium;
  final bool deleted;
  final bool banned;
  final bool moderator;

  String name;

  BotUser(
      {required this.id,
      required this.name,
      required this.isPremium,
      required this.deleted,
      required this.banned,
      required this.moderator}) {
    var markedAsPremium = name.contains('⭐');

    if (isPremium && !markedAsPremium) {
      name += ' ⭐';
    } else if (!isPremium && markedAsPremium) {
      name = name.replaceAll(' ⭐', '');
    }
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'isPremium': isPremium, 'deleted': deleted, 'banned': banned, 'moderator': moderator};
}
