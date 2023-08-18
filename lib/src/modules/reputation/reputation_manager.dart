import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/core/database.dart';
import 'package:weather/src/core/chat.dart';
import '../utils.dart';
import './reputation.dart';

class ReputationManager {
  final Platform platform;
  final Database db;
  final Chat chat;

  late Reputation _reputation;

  ReputationManager({required this.platform, required this.db, required this.chat}) : _reputation = Reputation(db: db);

  void initialize() {
    _reputation.initialize();
  }

  void increaseReputation(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;

    var chatId = event.chatId;
    var fromUserId = event.userId;
    var toUserId = event.otherUserIds[0];
    var result = await _reputation.updateReputation(
        chatId: chatId, change: ReputationChangeOption.increase, fromUserId: fromUserId, toUserId: toUserId);

    _handleReputationChange(event, result);
  }

  void decreaseReputation(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;

    var chatId = event.chatId;
    var fromUserId = event.userId;
    var toUserId = event.otherUserIds[0];
    var result = await _reputation.updateReputation(
        chatId: chatId, change: ReputationChangeOption.decrease, fromUserId: fromUserId, toUserId: toUserId);

    _handleReputationChange(event, result);
  }

  void sendReputationList(MessageEvent event) async {
    var chatId = event.chatId;
    var reputationData = await _reputation.getReputationData(chatId);
    var reputationMessage = _buildReputationListMessage(chatId, reputationData);
    var successfulMessage = chat.getText(event.chatId, 'reputation.other.list', {'reputation': reputationMessage});

    sendOperationMessage(chatId, platform: platform, operationResult: reputationMessage.isNotEmpty, successfulMessage: successfulMessage);
  }

  void createReputation(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.otherUserIds[0];
    var result = await _reputation.createReputationData(chatId, userId);
    var successfulMessage = chat.getText(chatId, 'general.success');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  void _handleReputationChange(MessageEvent event, ReputationChangeResult change) async {
    var chatId = event.chatId;

    switch (change) {
      case ReputationChangeResult.increaseSuccess:
        await platform.sendMessage(chatId, translation: 'reputation.change.increase_success');
        break;

      case ReputationChangeResult.decreaseSuccess:
        await platform.sendMessage(chatId, translation: 'reputation.change.decrease_success');
        break;

      case ReputationChangeResult.userNotFound:
        await platform.sendMessage(event.chatId, translation: 'reputation.change.user_not_found');
        break;

      case ReputationChangeResult.selfUpdate:
        await platform.sendMessage(event.chatId, translation: 'reputation.change.self_update');
        break;

      case ReputationChangeResult.notEnoughOptions:
        await platform.sendMessage(event.chatId, translation: 'reputation.change.not_enough_options');
        break;

      case ReputationChangeResult.systemError:
        await platform.sendMessage(event.chatId, translation: 'general.something_went_wrong');
        break;
    }
  }

  String _buildReputationListMessage(String chatId, List<ReputationData> reputationData) {
    var reputationMessage = '';

    reputationData.forEach((reputation) {
      reputationMessage +=
          chat.getText(chatId, 'reputation.other.line', {'name': reputation.name, 'reputation': reputation.reputation.toString()});
    });

    return reputationMessage;
  }
}
