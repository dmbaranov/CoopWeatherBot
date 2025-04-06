T? _fromJson<T>(dynamic json, T Function(Map<String, dynamic>) fromJson) {
  return json != null ? fromJson(json as Map<String, dynamic>) : null;
}

class ConversatorConfig {
  final String instructions;

  ConversatorConfig({required this.instructions});

  ConversatorConfig.fromJson(Map<dynamic, dynamic> json) : instructions = json['instructions'];
}

class NewsConfig {
  final bool disabled;

  NewsConfig({required this.disabled});

  NewsConfig.fromJson(Map<dynamic, dynamic> json) : disabled = json['disabled'];
}

class ChatConfig {
  final String chatId;
  final ConversatorConfig? conversatorConfig;
  final NewsConfig? newsConfig;

  ChatConfig({required this.chatId, this.conversatorConfig, this.newsConfig});

  ChatConfig.fromJson(Map<dynamic, dynamic> json)
      : chatId = json['chatId'],
        conversatorConfig = _fromJson(json['conversator'], ConversatorConfig.fromJson),
        newsConfig = _fromJson(json['news'], NewsConfig.fromJson);
}
