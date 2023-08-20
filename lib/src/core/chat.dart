import 'dart:io';
import 'dart:convert';
import 'package:weather/src/globals/chat_platform.dart';

import './database.dart';

class ChatData {
  final String id;
  final String name;
  final ChatPlatform platform;
  final String swearwordsConfig;

  ChatData({required this.id, required this.name, required this.platform, required this.swearwordsConfig});
}

class Chat {
  final Database db;
  final Map<String, Map<String, dynamic>> _chatToSwearwordsConfig = {};

  Chat({required this.db});

  Future<void> initialize() async {
    await _updateSwearwordsConfigs();
  }

  Future<bool> createChat({required String id, required String name, required ChatPlatform platform}) async {
    var creationResult = await db.chat.createChat(id, name, platform.value);

    await _updateSwearwordsConfigs();

    return creationResult == 1;
  }

  Future<List<String>> getAllChatIdsForPlatform(ChatPlatform platform) {
    return db.chat.getAllChatIds(platform.value);
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

  Future<bool> setSwearwordsConfig(String chatId, String config) async {
    var fileExists = await File('assets/swearwords/swearwords.$config.json').exists();

    if (!fileExists) {
      return false;
    }

    var updateResult = await db.chat.setChatSwearwordsConfig(chatId, config);

    if (updateResult != 1) {
      return false;
    }

    await _updateSwearwordsConfigs();

    return true;
  }

  // TODO: instead of this function, check _config every time check _config first, if not found, then fetch from database and update _config
  Future<void> _updateSwearwordsConfigs() async {
    var allChats = await db.chat.getAllChats();

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
