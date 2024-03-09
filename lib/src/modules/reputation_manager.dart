import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/event_bus.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/reputation.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/utils/logger.dart';
import 'utils.dart';

class ReputationManager {
  final Platform platform;
  final Database db;
  final EventBus eventBus;
  final Chat chat;
  final Logger _logger;
  final Reputation _reputation;

  ReputationManager({required this.platform, required this.db, required this.eventBus, required this.chat})
      : _logger = getIt<Logger>(),
        _reputation = Reputation(db: db, eventBus: eventBus);

  void initialize() {
    _reputation.initialize();
  }

  void increaseReputation(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;
    _logger.i('Increasing reputation: $event');

    var chatId = event.chatId;
    var fromUserId = event.userId;
    var toUserId = event.otherUserIds[0];
    var successfulMessage = chat.getText(chatId, 'reputation.change.increase_success');

    _reputation
        .updateReputation(chatId: chatId, change: ReputationChangeOption.increase, fromUserId: fromUserId, toUserId: toUserId)
        .then((result) => sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage))
        .catchError((error) => handleException<ReputationException>(error, chatId, platform));
  }

  void decreaseReputation(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;
    _logger.i('Decreasing reputation: $event');

    var chatId = event.chatId;
    var fromUserId = event.userId;
    var toUserId = event.otherUserIds[0];
    var successfulMessage = chat.getText(chatId, 'reputation.change.decrease_success');

    _reputation
        .updateReputation(chatId: chatId, change: ReputationChangeOption.decrease, fromUserId: fromUserId, toUserId: toUserId)
        .then((result) => sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage))
        .catchError((error) => handleException<ReputationException>(error, chatId, platform));
  }

  void sendReputationList(MessageEvent event) async {
    _logger.i('Sending reputation list: $event');

    var chatId = event.chatId;
    var reputationData = await _reputation.getReputationData(chatId);
    var reputationMessage = _buildReputationListMessage(chatId, reputationData);
    var successfulMessage = chat.getText(event.chatId, 'reputation.other.list', {'reputation': reputationMessage});

    sendOperationMessage(chatId, platform: platform, operationResult: reputationMessage.isNotEmpty, successfulMessage: successfulMessage);
  }

  void createReputation(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;
    _logger.i('Creating reputation data: $event');

    var chatId = event.chatId;
    var userId = event.otherUserIds[0];
    var result = await _reputation.createReputationData(chatId, userId);
    var successfulMessage = chat.getText(chatId, 'general.success');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  String _buildReputationListMessage(String chatId, List<ChatReputationData> reputationData) {
    var reputationMessage = '';

    reputationData.forEach((reputation) {
      reputationMessage +=
          chat.getText(chatId, 'reputation.other.line', {'name': reputation.name, 'reputation': reputation.reputation.toString()});
    });

    return reputationMessage;
  }
}
