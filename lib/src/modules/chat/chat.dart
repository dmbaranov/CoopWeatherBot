import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/repositories/chat_repository.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/globals/chat_data.dart';

class Chat {
  final ChatPlatform chatPlatform;
  final ChatRepository _chatDb;

  Chat({required this.chatPlatform}) : _chatDb = getIt<ChatRepository>();

  Future<ChatData?> getSingleChat({required String chatId}) {
    return _chatDb.getSingleChat(chatId: chatId);
  }

  Future<List<String>> getAllChatIdsForPlatform(ChatPlatform platform) {
    return _chatDb.getAllChatIds(platform.value);
  }
}
