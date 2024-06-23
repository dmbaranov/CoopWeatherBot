import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/module_manager.dart';
import 'package:weather/src/globals/chat_reputation_data.dart';
import 'package:weather/src/globals/message_event.dart';
import 'reputation.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class ReputationManager implements ModuleManager {
  @override
  final Platform platform;
  @override
  final ModulesMediator modulesMediator;
  final Reputation _reputation;
  final Swearwords _sw;

  ReputationManager(this.platform, this.modulesMediator)
      : _reputation = Reputation(),
        _sw = getIt<Swearwords>();

  @override
  Reputation get module => _reputation;

  @override
  void initialize() {
    _reputation.initialize();
  }

  void increaseReputation(MessageEvent event) async {
    if (!otherUserCheck(platform, event)) return;

    var chatId = event.chatId;
    var fromUserId = event.userId;
    var toUserId = event.otherUser!.id;
    var successfulMessage = _sw.getText(chatId, 'reputation.change.increase_success');

    _reputation
        .updateReputation(chatId: chatId, change: ReputationChangeOption.increase, fromUserId: fromUserId, toUserId: toUserId)
        .then((result) => sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage))
        .catchError((error) => handleException<ReputationException>(error, chatId, platform));
  }

  void decreaseReputation(MessageEvent event) async {
    if (!otherUserCheck(platform, event)) return;

    var chatId = event.chatId;
    var fromUserId = event.userId;
    var toUserId = event.otherUser!.id;
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
    if (!otherUserCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.otherUser!.id;
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
