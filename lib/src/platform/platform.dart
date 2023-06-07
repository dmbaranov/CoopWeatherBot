import 'package:weather/src/platform/shared/chat_platform.dart';
import 'package:weather/src/platform/shared/message_event.dart';

import 'package:weather/src/platform/telegram/initialize_platform.dart';
import 'package:weather/src/platform/telegram/post_start.dart';
import 'package:weather/src/platform/telegram/event_mappers.dart';

import 'package:weather/src/platform/discord/initialize_platform.dart';
import 'package:weather/src/platform/discord/post_start.dart';
import 'package:weather/src/platform/discord/event_mappers.dart';

const platformToolsMap = {
  ChatPlatform.telegram: {
    'initializePlatform': initializeTelegram,
    'postStart': telegramPostStart,
    'eventMappers': {'mapToGeneralMessageEvent': mapTelegramEventToGeneralMessageEvent}
  },
  ChatPlatform.discord: {
    'initializePlatform': initializeDiscord,
    'postStart': discordPostStart,
    'eventMappers': {'mapToGeneralMessageEvent': mapDiscordEventToGeneralMessageEvent}
  }
};

class Platform {
  final ChatPlatform platform;
  final Map<ChatPlatform, dynamic> _platformTools = platformToolsMap;

  late dynamic botInstance;

  Platform({required this.platform});

  Future<void> initializePlatform(String token) async {
    botInstance = await _getPlatformToolMethod(_platformTools[platform], 'initializePlatform')(token);
  }

  MessageEvent transformToGeneralMessageEvent(event) {
    return _getPlatformToolMethod(_platformTools[platform], 'eventMappers.mapToGeneralMessageEvent')(event);
  }

  Function _getPlatformToolMethod(Map<String, dynamic> object, String pathString) {
    var path = pathString.split('.');

    if (path.length == 1) {
      return object[path[0]];
    }

    var firstItem = path.first;

    if (object[firstItem] != null) {
      return _getPlatformToolMethod(object[firstItem], path.sublist(1).join('.'));
    }

    throw Exception("Couldn't get platform tool for platform $platform with path $path");
  }
}
