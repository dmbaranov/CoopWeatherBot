import 'package:injectable/injectable.dart';
import 'package:weather/src/core/repositories/chat_config_repository.dart';
import 'package:weather/src/globals/chat_config_data.dart';

@singleton
class ChatConfig {
  final ChatConfigRepository _chatConfigDb;
  final Map<String, ChatConfigData> _chatConfigData = {};

  ChatConfig(this._chatConfigDb);

  @PostConstruct()
  void initialize() async {
    var configs = await _chatConfigDb.getAllPlatformConfigs();

    configs.forEach((config) {
      _chatConfigData[config.chatId] = config;
    });
  }

  void updateChatConfig(String chatId) async {
    var config = await _chatConfigDb.getChatConfig(chatId);

    if (config != null) {
      _chatConfigData[config.chatId] = config;
    } else {
      _chatConfigData.remove(chatId);
    }
  }

  ConversatorConfig? getConversatorConfig(String chatId) {
    return _chatConfigData[chatId]?.conversatorConfig;
  }

  NewsConfig? getNewsConfig(String chatId) {
    return _chatConfigData[chatId]?.newsConfig;
  }
}
