import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'utils.dart';

class CheckManager {
  final Platform platform;
  final Database db;
  final Chat chat;

  CheckManager({required this.platform, required this.db, required this.chat});

  void initialize() {
    // init check core
    _subscribeToCheckUpdates();
  }

  void checkMessage(MessageEvent event) {
    if (!userIdsCheck(platform, event)) return;
    if (!messageEventParametersCheck(platform, event, 2)) return;

    print('Remind about ${event.parameters[1]} from ${event.otherUserIds} in ${event.parameters[0]}');
  }

  void _subscribeToCheckUpdates() {
    print('subscribing to check updates');
  }
}
