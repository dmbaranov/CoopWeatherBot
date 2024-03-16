import 'package:dotenv/dotenv.dart';
import 'package:weather/src/globals/chat_platform.dart';

class Config {
  late final String _dbUser;
  late final String _dbPassword;
  late final String _token;
  late final String _adminId;
  late final String _githubRepo;
  late final String _youtubeKey;
  late final String _openWeatherKey;
  late final String _conversatorKey;
  late final ChatPlatform _chatPlatform;
  late final bool _isProduction;

  String get dbUser => _dbUser;

  String get dbPassword => _dbPassword;

  String get token => _token;

  String get adminId => _adminId;

  String get githubRepo => _githubRepo;

  String get youtubeKey => _youtubeKey;

  String get openWeatherKey => _openWeatherKey;

  String get conversatorKey => _conversatorKey;

  ChatPlatform get chatPlatform => _chatPlatform;

  bool get isProduction => _isProduction;

  void initialize() {
    var env = DotEnv(includePlatformEnvironment: true)..load();

    _dbUser = env['dbuser']!;
    _dbPassword = env['dbpassword']!;
    _token = env['bottoken']!;
    _adminId = env['adminid']!;
    _githubRepo = env['githubrepo']!;
    _youtubeKey = env['youtube']!;
    _openWeatherKey = env['openweather']!;
    _conversatorKey = env['conversatorkey']!;
    _chatPlatform = _getPlatform(env['platform']!);
    _isProduction = _getIsProductionMode(env['isproduction']!);
  }

  ChatPlatform _getPlatform(String envPlatform) {
    if (envPlatform == 'telegram') return ChatPlatform.telegram;
    if (envPlatform == 'discord') return ChatPlatform.discord;

    throw Exception('Invalid platform $envPlatform');
  }

  bool _getIsProductionMode(String envIsProduction) {
    return int.parse(envIsProduction ?? '0') == 1;
  }
}
