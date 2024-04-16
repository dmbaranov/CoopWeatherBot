import 'chat_platform.dart';

class ChatData {
  final String id;
  final String name;
  final ChatPlatform platform;
  final String swearwordsConfig;

  ChatData({required this.id, required this.name, required this.platform, required this.swearwordsConfig});
}
