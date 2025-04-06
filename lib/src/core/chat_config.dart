import 'package:injectable/injectable.dart';
import 'package:weather/src/core/repositories/chat_config_repository.dart';
import 'package:weather/src/injector/injection.dart';

@singleton
@Order(2)
class ChatConfig {
  final ChatConfigRepository _chatConfigDb;

  ChatConfig() : _chatConfigDb = getIt<ChatConfigRepository>();

  @PostConstruct()
  void initialize() async {
    var config = await _chatConfigDb.getAllPlatformConfigs();

    print('config $config');
  }
}
