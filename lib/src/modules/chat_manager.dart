import 'dart:io';
import 'dart:convert';
import 'database-manager/database_manager.dart';

enum ChatPlatform {
  telegram('telegram'),
  discord('discord');

  final String value;

  const ChatPlatform(this.value);

  factory ChatPlatform.fromString(String platform) {
    return values.firstWhere((platform) => platform == platform);
  }
}

class ChatManager {
  final DatabaseManager dbManager;
  final Map<String, Map<String, dynamic>> _chatToSwearwordsConfig = {};

  ChatManager({required this.dbManager});

  Future<void> initialize() async {
    await _setupSwearwordsConfigs();
  }

  Future<bool> createChat({required String id, required String name, required ChatPlatform platform}) async {
    var creationResult = await dbManager.chat.createChat(id, name, platform.value);

    return creationResult == 1;
  }

  Future<List<String>> getAllChatIdsForPlatform(ChatPlatform platform) {
    return dbManager.chat.getAllChatIds(platform.value);
  }

  String getText(String chatId, String path, [Map<String, String>? replacements]) {
    var swearwords = _chatToSwearwordsConfig[chatId];

    if (swearwords == null) {
      return path;
    }

    var text = _getNestedProperty(swearwords, path.split('.')) ?? path;

    if (replacements == null) {
      return text;
    }

    replacements.keys.forEach((replacementKey) {
      text = text.replaceAll('\$$replacementKey', replacements[replacementKey]!);
    });

    return text;
  }

  Future<void> _setupSwearwordsConfigs() async {
    var allChats = await dbManager.chat.getAllChats();

    await Future.forEach(allChats, (chat) async {
      var chatConfig = await File('assets/swearwords/swearwords.${chat.swearwordsConfig}.json').readAsString();

      _chatToSwearwordsConfig[chat.id] = json.decode(chatConfig);
    });
  }

  String? _getNestedProperty(Map<String, dynamic> object, List<String> path) {
    if (path.length == 1) {
      return object[path[0]];
    }

    var firstItem = path.first;

    if (object[firstItem] != null) {
      return _getNestedProperty(object[firstItem], path.sublist(1));
    }

    return null;
  }
}
