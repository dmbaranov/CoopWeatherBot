import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/chat_reputation_data.dart';
import 'package:weather/src/globals/message_event.dart';
import 'reputation.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class ReputationManager {
  final Platform platform;
  final ModulesMediator modulesMediator;
  final Reputation _reputation;
  final Swearwords _sw;

  ReputationManager({required this.platform, required this.modulesMediator})
      : _reputation = Reputation(),
        _sw = getIt<Swearwords>();

  void initialize() {
    _reputation.initialize();
    modulesMediator.registerModule(_reputation);
  }

  void increaseReputation(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;

    var chatId = event.chatId;
    var fromUserId = event.userId;
    var toUserId = event.otherUserIds[0];
    var successfulMessage = _sw.getText(chatId, 'reputation.change.increase_success');

    _reputation
        .updateReputation(chatId: chatId, change: ReputationChangeOption.increase, fromUserId: fromUserId, toUserId: toUserId)
        .then((result) => sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage))
        .catchError((error) => handleException<ReputationException>(error, chatId, platform));
  }

  void decreaseReputation(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;

    var chatId = event.chatId;
    var fromUserId = event.userId;
    var toUserId = event.otherUserIds[0];
    var successfulMessage = _sw.getText(chatId, 'reputation.change.decrease_success');

    _reputation
        .updateReputation(chatId: chatId, change: ReputationChangeOption.decrease, fromUserId: fromUserId, toUserId: toUserId)
        .then((result) => sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage))
        .catchError((error) => handleException<ReputationException>(error, chatId, platform));
  }

  void sendReputationList(MessageEvent event) async {
    var chatId = event.chatId;
    var reputationData = await _reputation.getReputationData(chatId);
    var reputationMessage = _buildReputationListMessage(chatId, reputationData);
    var successfulMessage = _sw.getText(event.chatId, 'reputation.other.list', {'reputation': reputationMessage});

    sendOperationMessage(chatId, platform: platform, operationResult: reputationMessage.isNotEmpty, successfulMessage: successfulMessage);
  }

  void createReputation(MessageEvent event) async {
    if (!userIdsCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.otherUserIds[0];
    var result = await _reputation.createReputationData(chatId, userId);
    var successfulMessage = _sw.getText(chatId, 'general.success');

    sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage);
  }

  String _buildReputationListMessage(String chatId, List<ChatReputationData> reputationData) {
    var reputationMessage = '';

    reputationData.forEach((reputation) {
      reputationMessage +=
          _sw.getText(chatId, 'reputation.other.line', {'name': reputation.name, 'reputation': reputation.reputation.toString()});
    });

    return reputationMessage;
  }
}
