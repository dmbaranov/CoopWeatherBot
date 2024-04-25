import 'package:dotenv/dotenv.dart';
import 'package:injectable/injectable.dart';
import 'package:weather/src/globals/chat_platform.dart';

@singleton
class Config {
  late final String _dbHost;
  late final int _dbPort;
  late final String _dbUser;
  late final String _dbPassword;
  late final String _dbDatabase;
  late final String _token;
  late final String _botName;
  late final String _adminId;
  late final String _githubRepo;
  late final String _youtubeKey;
  late final String _openWeatherKey;
  late final String _conversatorKey;
  late final ChatPlatform _chatPlatform;
  late final bool _isProduction;

  String get dbHost => _dbHost;

  int get dbPort => _dbPort;

  String get dbUser => _dbUser;

  String get dbPassword => _dbPassword;

  String get dbDatabase => _dbDatabase;

  String get token => _token;

  String get botName => _botName;

  String get adminId => _adminId;

  String get githubRepo => _githubRepo;

  String get youtubeKey => _youtubeKey;

  String get openWeatherKey => _openWeatherKey;

  String get conversatorKey => _conversatorKey;

  ChatPlatform get chatPlatform => _chatPlatform;

  bool get isProduction => _isProduction;

  @PostConstruct()
  void initialize() {
    var env = DotEnv(includePlatformEnvironment: true)..load();

    _dbHost = env['dbhost']!;
    _dbPort = int.parse(env['dbport']!);
    _dbUser = env['dbuser']!;
    _dbPassword = env['dbpassword']!;
    _dbDatabase = env['dbdatabase']!;
    _botName = env['botname']!;
    _token = env['bottoken']!;
    _adminId = env['adminid']!;
    _githubRepo = env['githubrepo']!;
    _youtubeKey = env['youtube']!;
    _openWeatherKey = env['openweather']!;
    _conversatorKey = env['conversatorkey']!;
    _chatPlatform = _getPlatform(env['platform']);
    _isProduction = _getIsProductionMode(env['isproduction']);
  }

  ChatPlatform _getPlatform(String? envPlatform) {
    if (envPlatform == 'telegram') return ChatPlatform.telegram;
    if (envPlatform == 'discord') return ChatPlatform.discord;

    throw Exception('Invalid platform $envPlatform');
  }

  bool _getIsProductionMode(String? envIsProduction) {
    return int.parse(envIsProduction ?? '0') == 1;
  }
}
