import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:weather/src/globals/chat_config_data.dart';

import 'repository.dart';

@singleton
class ChatConfigRepository extends Repository {
  ChatConfigRepository({required super.db}) : super(repositoryName: 'chat_config');

  Future<List<ChatConfig>> getAllPlatformConfigs() async {
    var configs = await db.executeQuery(queriesMap['get_all_configs']);

    if (configs == null || configs.isEmpty) {
      return [];
    }

    return configs.map((config) => _mapChatConfig(config.toColumnMap())).toList();
  }

  ChatConfig _mapChatConfig(Map<String, dynamic> chatConfig) {
    var rawConfig = jsonDecode(chatConfig['config']) as Map<String, dynamic>;
    rawConfig['chatId'] = chatConfig['chat_id'];

    return ChatConfig.fromJson(rawConfig);
  }
}
