import 'package:weather/src/core/swearwords.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/platform/platform.dart';
import 'package:weather/src/globals/message_event.dart';
import 'package:weather/src/utils/logger.dart';
import 'check_reminder.dart';
import '../modules_mediator.dart';
import '../utils.dart';

class CheckReminderManager {
  final Platform platform;
  final ModulesMediator modulesMediator;
  final Logger _logger;
  final Swearwords _sw;
  final CheckReminder _checkReminder;

  CheckReminderManager({required this.platform, required this.modulesMediator})
      : _logger = getIt<Logger>(),
        _sw = getIt<Swearwords>(),
        _checkReminder = CheckReminder();

  void initialize() {
    _checkReminder.initialize();
    _subscribeToCheckUpdates();
    modulesMediator.registerModule(_checkReminder);
  }

  void checkMessage(MessageEvent event) async {
    if (!messageEventParametersCheck(platform, event)) return;

    var chatId = event.chatId;
    var userId = event.userId;
    var period = event.parameters[0];
    var message = event.parameters.sublist(1).join(' ');
    var successfulMessage = _sw.getText(chatId, 'general.success');

    _checkReminder
        .createCheckReminder(chatId: chatId, userId: userId, period: period, message: message)
        .then((result) => sendOperationMessage(chatId, platform: platform, operationResult: result, successfulMessage: successfulMessage))
        .catchError((error) => handleException<CheckReminderException>(error, chatId, platform));
  }

  void _subscribeToCheckUpdates() {
    _checkReminder.checkReminderStream.listen((checkReminder) async {
      var userData = await modulesMediator.user.getSingleUserForChat(checkReminder.chatId, checkReminder.userId);

      if (userData != null) {
        var checkReminderMessage =
            _sw.getText(checkReminder.chatId, 'check_reminder.reminder', {'user': userData.name, 'message': checkReminder.message});

        sendOperationMessage(checkReminder.chatId, platform: platform, operationResult: true, successfulMessage: checkReminderMessage);
      } else {
        _logger.e('Failed to send reminder: $checkReminder');
      }
    });
  }
}
