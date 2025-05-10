T? _fromJson<T>(dynamic json, T Function(Map<String, dynamic>) fromJson) {
  return json != null ? fromJson(json as Map<String, dynamic>) : null;
}

class ConversatorConfig {
  final String? instructions;

  ConversatorConfig({this.instructions});

  ConversatorConfig.fromJson(Map<dynamic, dynamic> json) : instructions = json['instructions'];
}

class NewsConfig {
  final bool? disabled;

  NewsConfig({this.disabled});

  NewsConfig.fromJson(Map<dynamic, dynamic> json) : disabled = json['disabled'];
}

class SwearwordsConfig {
  final String? swearwords;

  SwearwordsConfig({this.swearwords});

  SwearwordsConfig.fromJson(Map<dynamic, dynamic> json) : swearwords = json['swearwords'];
}

class ChatConfigData {
  final String chatId;
  final ConversatorConfig? conversatorConfig;
  final NewsConfig? newsConfig;
  final SwearwordsConfig? swearwordsConfig;

  ChatConfigData({required this.chatId, this.conversatorConfig, this.newsConfig, this.swearwordsConfig});

  ChatConfigData.fromJson(Map<dynamic, dynamic> json)
      : chatId = json['chatId'],
        conversatorConfig = _fromJson(json['conversator'], ConversatorConfig.fromJson),
        newsConfig = _fromJson(json['news'], NewsConfig.fromJson),
        swearwordsConfig = _fromJson(json['swearwords'], SwearwordsConfig.fromJson);
}
