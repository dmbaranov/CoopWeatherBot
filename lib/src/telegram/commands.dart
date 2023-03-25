import 'dart:convert';
import 'dart:math';
import 'dart:io' as io;
import 'package:teledart/model.dart';
import 'package:weather/src/modules/accordion_poll.dart';
import 'package:weather/src/modules/chat_manager.dart';
import 'package:weather/src/modules/reputation.dart';

import './bot.dart';
import './utils.dart';

void addCity(TelegramBot self, TeleDartMessage message) async {
  var cityToAdd = getOneParameterFromMessage(message);

  var result = await self.weatherManager.addCity(message.chat.id.toString(), cityToAdd);

  if (result) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('weather.cities.added', {'city': cityToAdd}));
  } else {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }
}

void removeCity(TelegramBot self, TeleDartMessage message) async {
  var cityToRemove = getOneParameterFromMessage(message);

  var result = await self.weatherManager.removeCity(message.chat.id.toString(), cityToRemove);

  if (result) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('weather.cities.removed', {'city': cityToRemove}));
  } else {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }
}

void getWatchlist(TelegramBot self, TeleDartMessage message) async {
  var cities = await self.weatherManager.getWatchList(message.chat.id.toString());
  var citiesString = cities.join('\n');

  await self.telegram.sendMessage(message.chat.id, self.sm.get('weather.cities.watchlist', {'cities': citiesString}));
}

void getWeatherForCity(TelegramBot self, TeleDartMessage message) async {
  var city = getOneParameterFromMessage(message);

  if (city.isEmpty) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));

    return;
  }

  var temperature = await self.weatherManager.getWeatherForCity(city);

  if (temperature != null) {
    await self.telegram
        .sendMessage(message.chat.id, self.sm.get('weather.cities.temperature', {'city': city, 'temperature': temperature.toString()}));
  } else {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }
}

void setNotificationHour(TelegramBot self, TeleDartMessage message) async {
  var nextHour = getOneParameterFromMessage(message);

  var result = await self.weatherManager.setNotificationHour(message.chat.id.toString(), int.parse(nextHour));

  if (result) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('weather.other.notification_hour_set', {'hour': nextHour}));
  } else {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }
}

void bullyTagUser(TelegramBot self, TeleDartMessage message) async {
  var denisId = 354903232;
  var messageAuthorId = message.from?.id;

  if (messageAuthorId == self.adminId) {
    await self.telegram.sendMessage(message.chat.id, '@daimonil');
  } else if (messageAuthorId == denisId) {
    await self.telegram.sendMessage(message.chat.id, '@dmbaranov_io');
  }
}

void writeToCoop(TelegramBot self, TeleDartMessage message) async {
  // TODO: add parameter to get chatId here and send message there
  await message.reply('Temporarily disabled');
  // if (message.text == null) {
  //   await self.telegram.sendMessage(message.chat.id, self.sm.get('do_not_do_this'));
  //
  //   return;
  // }
  //
  // var text = getFullMessageText(message);
  //
  // print('${message.from?.toJson()} is writing to Coop: ${message.toJson()}');
  //
  // try {
  //   await self.telegram.sendMessage(self.chatId, text);
  // } catch (e) {
  //   await self.telegram.sendMessage(message.chat.id, self.sm.get('do_not_do_this'));
  // }
}

void postUpdateMessage(TelegramBot self) async {
  var commitsApiUrl = 'https://api.github.com/repos${self.repoUrl}/commits';

  var request = await io.HttpClient().getUrl(Uri.parse(commitsApiUrl));
  var response = await request.close();
  var rawResponse = '';

  await for (var contents in response.transform(Utf8Decoder())) {
    rawResponse += contents;
  }

  var responseJson = json.decode(rawResponse);
  var commitMessage = responseJson[0]['commit']['message'];

  var updateMessage = self.sm.get('general.update_completed', {'update': commitMessage});

  var chatIds = await self.chatManager.getAllChatIds(ChatPlatform.telegram);

  chatIds.forEach((chatId) {
    self.telegram.sendMessage(int.parse(chatId), updateMessage);
  });
}

Future<void> sendNewsToChat(TelegramBot self, [TeleDartMessage? message]) async {
  // TODO: somehow this sends news to the chat even if ask in dm
  var instantViewUrl = 'a.devs.today/';

  if (message != null) {
    var news = await self.panoramaNews.getNews(message.chat.id.toString());

    if (news != null) {
      var newsMessage = '${news.title}\n\nFull<a href="${instantViewUrl + news.url}">:</a> ${news.url}';

      self.telegram.sendMessage(message.chat.id, newsMessage, parseMode: 'HTML');

      return;
    }
  }

  // TODO: move sendToAllChats to a separate function
  var chatIds = await self.chatManager.getAllChatIds(ChatPlatform.telegram);

  await Future.forEach(chatIds, (chatId) async {
    var news = await self.panoramaNews.getNews(chatId);

    if (news != null) {
      var newsMessage = '${news.title}\n\nFull<a href="${instantViewUrl + news.url}">:</a> ${news.url}';

      self.telegram.sendMessage(chatId, newsMessage, parseMode: 'HTML');
    }
  });
}

Future<void> sendJokeToChat(TelegramBot self, [TeleDartMessage? message]) async {
  var joke = await self.dadJokes.getJoke();

  if (message != null) {
    await self.telegram.sendMessage(message.chat.id, joke.joke);

    return;
  }

  var chatIds = await self.chatManager.getAllChatIds(ChatPlatform.telegram);

  chatIds.forEach((chatId) {
    self.telegram.sendMessage(int.parse(chatId), joke.joke);
  });
}

Future<void> sendRealMusic(TelegramBot self, TeleDartMessage message) async {
  // TODO: add a check that this chat exists. here and to the other commands
  if (message.text == null || message.text?.contains('music.youtube.com') == false) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));

    return;
  }

  var rawText = message.text?.split(' ');

  if (rawText == null) {
    return;
  }

  var text = rawText.sublist(1).join(' ');
  text = text.replaceAll('music.', '');

  try {
    await self.telegram.sendMessage(message.chat.id, text);
  } catch (e) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }
}

Future<void> searchYoutubeTrack(TelegramBot self, TeleDartMessage message) async {
  var query = getFullMessageText(message);

  if (query.isEmpty) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));

    return;
  }

  var videoUrl = await self.youtube.getYoutubeVideoUrl(query);

  if (videoUrl.isEmpty) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  } else {
    await self.telegram.sendMessage(message.chat.id, videoUrl);
  }
}

Future<void> searchYoutubeTrackInline(TelegramBot self, TeleDartInlineQuery query) async {
  var searchResults = await self.youtube.getYoutubeSearchResults(query.query);
  List items = searchResults['items'];
  var inlineQueryResult = [];

  items.forEach((searchResult) {
    var videoId = searchResult['id']['videoId'];
    var videoData = searchResult['snippet'];
    var videoUrl = 'https://www.youtube.com/watch?v=$videoId';

    inlineQueryResult.add(InlineQueryResultVideo(
        id: videoId,
        title: videoData['title'],
        thumbUrl: videoData['thumbnails']['high']['url'],
        mimeType: 'video/mp4',
        videoDuration: 600,
        videoUrl: videoUrl,
        inputMessageContent: InputTextMessageContent(messageText: videoUrl, disableWebPagePreview: false)));
  });

  await self.bot.answerInlineQuery(query.id, [...inlineQueryResult], cacheTime: 10);
}

Future<void> updateReputation(TelegramBot self, TeleDartMessage message, ReputationChangeOption change) async {
  var chatId = message.chat.id;
  var fromUserId = message.from?.id.toString();
  var toUserId = message.replyToMessage?.from?.id.toString();

  var changeResult =
      await self.reputation.updateReputation(chatId: chatId.toString(), fromUserId: fromUserId, toUserId: toUserId, change: change);

  switch (changeResult) {
    case ReputationChangeResult.increaseSuccess:
      await self.telegram.sendMessage(chatId, self.sm.get('reputation.change.increase_success'));
      break;
    case ReputationChangeResult.decreaseSuccess:
      await self.telegram.sendMessage(chatId, self.sm.get('reputation.change.decrease_success'));
      break;
    case ReputationChangeResult.userNotFound:
      await self.telegram.sendMessage(chatId, self.sm.get('reputation.change.user_not_found'));
      break;
    case ReputationChangeResult.selfUpdate:
      await self.telegram.sendMessage(chatId, self.sm.get('reputation.change.self_update'));
      break;
    case ReputationChangeResult.notEnoughOptions:
      await self.telegram.sendMessage(chatId, self.sm.get('reputation.change.not_enough_options'));
      break;
    case ReputationChangeResult.systemError:
      await self.telegram.sendMessage(chatId, self.sm.get('general.something_went_wrong'));
      break;
  }
}

Future<void> sendReputationList(TelegramBot self, TeleDartMessage message) async {
  var reputationData = await self.reputation.getReputationMessage(message.chat.id.toString());
  var reputationMessage = '';

  reputationData.forEach((reputation) {
    reputationMessage += self.sm.get('reputation.other.line', {'name': reputation.name, 'reputation': reputation.reputation.toString()});
  });

  if (reputationMessage.isEmpty) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  } else {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('reputation.other.list', {'reputation': reputationMessage}));
  }
}

Future<void> checkIfAlive(TelegramBot self, TeleDartMessage message) async {
  await self.telegram.sendMessage(message.chat.id, self.sm.get('general.bot_is_alive'));
}

Future<void> startAccordionPoll(TelegramBot self, TeleDartMessage message) async {
  if (self.accordionPoll.isVoteActive) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('accordion.other.accordion_vote_in_progress'));

    return;
  }

  var votedMessageAuthor = message.replyToMessage?.from;

  if (votedMessageAuthor == null) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('accordion.other.message_not_chosen'));

    return;
  } else if (votedMessageAuthor.isBot) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('accordion.other.bot_vote_attempt'));

    return;
  }

  var chatId = message.chat.id.toString();
  const pollTime = 180;
  var pollOptions = [self.sm.get('accordion.options.yes'), self.sm.get('accordion.options.no'), self.sm.get('accordion.options.maybe')];

  self.accordionPoll.startPoll(votedMessageAuthor.id.toString());

  var createdPoll = await self.telegram.sendPoll(
    chatId,
    self.sm.get('accordion.other.title'),
    pollOptions,
    explanation: self.sm.get('accordion.other.explanation'),
    type: 'quiz',
    correctOptionId: Random().nextInt(pollOptions.length),
    openPeriod: pollTime,
  );

  var pollSubscription = self.bot.onPoll().listen((poll) {
    if (createdPoll.poll?.id != poll.id) {
      print('Wrong poll');

      return;
    }

    var currentPollResults = {
      AccordionVoteOption.yes: poll.options[0].voterCount,
      AccordionVoteOption.no: poll.options[1].voterCount,
      AccordionVoteOption.maybe: poll.options[2].voterCount
    };

    self.accordionPoll.voteResult = currentPollResults;
  });

  await Future.delayed(Duration(seconds: pollTime));

  var voteResult = self.accordionPoll.endVoteAndGetResults();

  switch (voteResult) {
    case AccordionVoteResults.yes:
      await self.telegram.sendMessage(chatId, self.sm.get('accordion.results.yes'));
      break;
    case AccordionVoteResults.no:
      await self.telegram.sendMessage(chatId, self.sm.get('accordion.results.no'));
      break;
    case AccordionVoteResults.maybe:
      await self.telegram.sendMessage(chatId, self.sm.get('accordion.results.maybe'));
      break;
    case AccordionVoteResults.noResults:
      await self.telegram.sendMessage(chatId, self.sm.get('accordion.results.noResults'));
      break;
  }

  await pollSubscription.cancel();
}

Future<void> getConversatorReply(TelegramBot self, TeleDartMessage message) async {
  var question = getFullMessageText(message);
  var reply = await self.conversator.getConversationReply(question);

  await self.telegram.sendMessage(message.chat.id, reply);
}

Future<void> addUser(TelegramBot self, TeleDartMessage message) async {
  var userData = message.replyToMessage?.from;

  if (userData == null || userData.isBot) {
    print('Invalid user data');

    return;
  }

  var fullUsername = '${userData.firstName} ';

  var originalUsername = userData.username;
  if (originalUsername != null) {
    fullUsername += '<$originalUsername> ';
  }

  var originalLastName = userData.lastName;
  if (originalLastName != null) {
    fullUsername += originalLastName;
  }

  var addResult = await self.userManager
      .addUser(id: userData.id.toString(), chatId: message.chat.id.toString(), name: fullUsername, isPremium: userData.isPremium ?? false);

  if (addResult) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('user.user_added'));
  } else {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }
}

Future<void> removeUser(TelegramBot self, TeleDartMessage message) async {
  var userData = message.replyToMessage?.from;

  if (userData == null || userData.isBot) {
    print('Invalid user data');

    return;
  }

  var chatId = message.chat.id.toString();
  var userId = userData.id.toString();
  var removeResult = await self.userManager.removeUser(chatId, userId);

  if (removeResult) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('user.user_removed'));
  } else {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }
}

Future<void> initChat(TelegramBot self, TeleDartMessage message) async {
  // TODO: also create a SYSTEM user for new chats. use it to change reputation, etc.
  var chatId = message.chat.id.toString();
  var chatName = message.chat.title.toString();

  var result = await self.chatManager.createChat(id: chatId, name: chatName);

  if (result) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('chat.initialization.success'));
  } else {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }
}

Future<void> createReputation(TelegramBot self, TeleDartMessage message) async {
  var chatId = message.chat.id.toString();
  var userId = message.replyToMessage?.from?.id;

  if (userId == null) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }

  var result = await self.reputation.createReputationData(chatId, userId.toString());

  if (result) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.success'));
  } else {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }
}

Future<void> createWeather(TelegramBot self, TeleDartMessage message) async {
  var chatId = message.chat.id.toString();

  var result = await self.weatherManager.createWeatherData(chatId);

  if (result) {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.success'));
  } else {
    await self.telegram.sendMessage(message.chat.id, self.sm.get('general.something_went_wrong'));
  }
}
