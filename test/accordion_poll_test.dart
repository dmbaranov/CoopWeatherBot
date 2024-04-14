import 'package:test/test.dart';
import 'package:weather/src/core/accordion_poll.dart';
import 'package:weather/src/globals/accordion_poll.dart';
import 'package:weather/src/globals/chat_platform.dart';
import 'package:weather/src/core/chat.dart';
import 'package:weather/src/core/user.dart';
import 'package:weather/src/core/event_bus.dart';
import 'utils/setup.dart';

void main() {
  setupTestEnvironment();
  late Chat chat;
  late User user;
  late AccordionPoll accordionPoll;

  setUp(() async {
    var eventBus = EventBus();

    chat = Chat();
    await chat.initialize();

    user = User();
    user.initialize();

    accordionPoll = AccordionPoll(eventBus: eventBus, chat: chat, pollTime: 1);
  });

  group('Accordion Poll', () {
    test('should not start poll if incorrect parameters are passed', () async {
      await chat.createChat(id: '123', name: 'test-telegram-chat', platform: ChatPlatform.telegram);
      await user.addUser(chatId: '123', userId: '123123', name: 'test-user-one');
      await user.addUser(chatId: '123', userId: '456456', name: 'test-user-two');
      var fromUser = await user.getSingleUserForChat('123', '123123');
      var toUser = await user.getSingleUserForChat('123', '456456');

      expect(accordionPoll.startPoll(chatId: '123', isBot: false, fromUser: fromUser, toUser: null),
          equals('accordion.other.message_not_chosen'));
      expect(accordionPoll.startPoll(chatId: '123', isBot: true, fromUser: fromUser, toUser: toUser),
          equals('accordion.other.bot_vote_attempt'));
    });

    test('should not start poll if there is already active poll', () async {
      var fromUser = await user.getSingleUserForChat('123', '123123');
      var toUser = await user.getSingleUserForChat('123', '456456');

      accordionPoll.startPoll(chatId: '123', isBot: false, fromUser: fromUser, toUser: toUser);

      expect(accordionPoll.startPoll(chatId: '123', isBot: false, fromUser: fromUser, toUser: toUser),
          equals('accordion.other.accordion_vote_in_progress'));
    });

    test('should update poll results and return final result when the poll completes', () async {
      var fromUser = await user.getSingleUserForChat('123', '123123');
      var toUser = await user.getSingleUserForChat('123', '456456');

      accordionPoll.startPoll(chatId: '123', isBot: false, fromUser: fromUser, toUser: toUser);
      accordionPoll.updatePollResults({AccordionVoteOption.yes: 2, AccordionVoteOption.no: 1, AccordionVoteOption.maybe: 0});

      var results = await accordionPoll.endVoteAndGetResults();

      expect(results, equals('accordion.results.yes'));
    });
  });
}
