enum ChatPlatform {
  telegram('telegram'),
  discord('discord');

  final String value;

  const ChatPlatform(this.value);

  factory ChatPlatform.fromString(String platform) {
    return values.firstWhere((platform) => platform == platform);
  }
}
