import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/repositories/chat_repository.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/chat_data.dart';

class Chat {
  final ChatPlatform chatPlatform;
  final ChatRepository _chatDb;
  final Swearwords _sw;

  Chat({required this.chatPlatform})
      : _chatDb = getIt<ChatRepository>(),
        _sw = getIt<Swearwords>();

  void initialize() {
    _initializeSwearwords();
  }

  Future<bool> createChat({required String id, required String name, required ChatPlatform platform}) async {
    var creationResult = await _chatDb.createChat(id, name, platform.value, _sw.defaultConfig);

    return creationResult == 1;
  }

  Future<ChatData?> getSingleChat({required String chatId}) {
    return _chatDb.getSingleChat(chatId: chatId);
  }

  Future<List<String>> getAllChatIdsForPlatform(ChatPlatform platform) {
    return _chatDb.getAllChatIds(platform.value);
  }

  Future<bool> setSwearwordsConfig(String chatId, String config) async {
    var configAllowed = await _sw.canSetSwearwordsConfig(config);

    if (!configAllowed) {
      return false;
    }

    var updateResult = await _chatDb.setChatSwearwordsConfig(chatId, config);

    if (updateResult != 1) {
      return false;
    }

    _sw.setChatSwearwords(chatId, config);
    return true;
  }

  void _initializeSwearwords() async {
    var platformChats = await getAllChatIdsForPlatform(chatPlatform);

    await Future.forEach(platformChats, (chatId) async {
      var chat = await getSingleChat(chatId: chatId);

      if (chat != null) {
        _sw.setChatSwearwords(chatId, chat.swearwordsConfig);
      }
    });
  }
}
