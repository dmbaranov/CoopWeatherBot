import 'dart:convert';
import 'dart:math';
import 'dart:io' as io;
import 'package:teledart/model.dart';
import 'package:weather/src/modules/accordion_poll.dart';
import 'package:weather/src/modules/reputation.dart';

import './bot.dart';
import './utils.dart';

void addCity(TelegramBot self, TeleDartMessage message) async {
  var cityToAdd = getOneParameterFromMessage(message);

  var result = await self.weatherManager.addCity(cityToAdd);

  if (result) {
    await message.reply('City $cityToAdd has been added to the watchlist!');
  } else {
    await message.reply('Error');
  }
}

void removeCity(TelegramBot self, TeleDartMessage message) async {
  var cityToRemove = getOneParameterFromMessage(message);

  var result = await self.weatherManager.removeCity(cityToRemove);

  if (result) {
    await message.reply('City $cityToRemove has been removed from the watchlist!');
  } else {
    await message.reply('Error');
  }
}

void getWatchlist(TelegramBot self, TeleDartMessage message) async {
  var citiesString = await self.weatherManager.getWatchList();

  await message.reply("I'm watching these cities:\n$citiesString");
}

void getWeatherForCity(TelegramBot self, TeleDartMessage message) async {
  var city = getOneParameterFromMessage(message);

  if (city.isEmpty) {
    await message.reply('Provide a city!');

    return;
  }

  var temperature = await self.weatherManager.getWeatherForCity(city);

  if (temperature != null) {
    await message.reply('In city $city the temperature is $temperature°C');
  } else {
    await message.reply('There was an error processing your request! Try again');
  }
}

void setNotificationHour(TelegramBot self, TeleDartMessage message) async {
  var nextHour = getOneParameterFromMessage(message);

  var result = self.weatherManager.setNotificationsHour(int.parse(nextHour));

  if (result) {
    await message.reply('Notification hour has been set to $nextHour');
  } else {
    await message.reply('Error');
  }
}

void getBullyWeatherForCity(TelegramBot self, TeleDartMessage message) async {
  var messageWords = message.text?.split(RegExp(r'(,)|(\s{1,})')).where((item) => item.isNotEmpty).toList();

  if (messageWords == null ||
      messageWords.length != 3 ||
      (messageWords[0] != self.sm.get('yo') && messageWords[1] != self.sm.get('dude'))) {
    return;
  }

  var city = messageWords[2];

  try {
    var temperature = await self.weatherManager.getWeatherForCity(city);

    if (temperature == null) {
      throw 'No temperature';
    }

    await message.reply(self.sm.get('weather_in_city', {'city': city, 'temp': temperature.toString()}));
  } catch (err) {
    print(err);

    await message.reply(self.sm.get('error_occurred'));
  }
}

void bullyTagUser(TelegramBot self, TeleDartMessage message) async {
  var denisId = 354903232;
  var messageAuthorId = message.from?.id;

  if (messageAuthorId == self.adminId) {
    await message.reply('@daimonil');
  } else if (messageAuthorId == denisId) {
    await message.reply('@dmbaranov_io');
  }
}

void writeToCoop(TelegramBot self, TeleDartMessage message) async {
  if (message.text == null) {
    await message.reply(self.sm.get('do_not_do_this'));

    return;
  }

  var text = getFullMessageText(message);

  print('${message.from?.toJson()} is writing to Coop: ${message.toJson()}');

  try {
    await self.telegram.sendMessage(self.chatId, text);
  } catch (e) {
    await message.reply(self.sm.get('do_not_do_this'));
  }
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

  var updateMessage = self.sm.get('update_completed', {'update': commitMessage});

  await self.telegram.sendMessage(self.chatId, updateMessage);
}

Future<void> sendNewsToChat(TelegramBot self) async {
  var instantViewUrl = 'a.devs.today/';
  var news = await self.panoramaNews.getNews();

  if (news.title.isEmpty) return;

  var message = '${news.title}\n\nFull<a href="${instantViewUrl + news.url}">:</a> ${news.url}';

  await self.telegram.sendMessage(self.chatId, message, parseMode: 'HTML');
}

Future<void> sendJokeToChat(TelegramBot self) async {
  var joke = await self.dadJokes.getJoke();

  await self.telegram.sendMessage(self.chatId, joke.joke);
}

Future<void> sendRealMusic(TelegramBot self, TeleDartMessage message) async {
  if (message.text == null || message.text?.contains('music.youtube.com') == false) {
    await message.reply(self.sm.get('do_not_do_this'));

    return;
  }

  var rawText = message.text?.split(' ');

  if (rawText == null) {
    return;
  }

  var text = rawText.sublist(1).join(' ');
  text = text.replaceAll('music.', '');

  try {
    await self.telegram.sendMessage(self.chatId, text);
  } catch (e) {
    await message.reply(self.sm.get('do_not_do_this'));
  }
}

Future<void> searchYoutubeTrack(TelegramBot self, TeleDartMessage message) async {
  var query = getFullMessageText(message);

  if (query.isEmpty) {
    await message.reply(self.sm.get('do_not_do_this'));

    return;
  }

  var videoUrl = await self.youtube.getYoutubeVideoUrl(query);

  if (videoUrl.isEmpty) {
    await message.reply(self.sm.get('not_found'));
  } else {
    await message.reply(videoUrl);
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

Future<void> updateReputation(TelegramBot self, TeleDartMessage message, ChangeOption change) async {
  var fromUserId = message.from?.id;
  var toUserId = message.replyToMessage?.from?.id;

  if (fromUserId == null || toUserId == null) {
    await message.reply(self.sm.get('error_occurred'));

    return;
  }

  var changeResult = await self.reputation.updateReputation(
      chatId: message.chat.id.toString(), fromUserId: fromUserId.toString(), toUserId: toUserId.toString(), change: change);

  if (changeResult) {
    await self.telegram.sendMessage(message.chat.id, 'Success');
  } else {
    await self.telegram.sendMessage(message.chat.id, 'Failure');
  }
}

Future<void> sendReputationList(TelegramBot self, TeleDartMessage message) async {
  var reputationData = await self.reputation.getReputationMessage(message.chat.id.toString());

  print('${reputationData[0].name}, ${reputationData[0].reputation}');

  // await message.reply(reputationMessage);
}

Future<void> checkIfAlive(TelegramBot self, TeleDartMessage message) async {
  await message.reply(self.sm.get('bot_is_alive'));
}

Future<void> startAccordionPoll(TelegramBot self, TeleDartMessage message) async {
  if (self.accordionPoll.isVoteActive) {
    await message.reply(self.sm.get('accordion_vote_in_progress'));

    return;
  }

  var votedMessageAuthor = message.replyToMessage?.from;

  if (votedMessageAuthor == null) {
    await message.reply(self.sm.get('accordion_message_not_chosen'));

    return;
  } else if (votedMessageAuthor.isBot) {
    await message.reply(self.sm.get('accordion_bot_message'));

    return;
  }

  const pollTime = 180;
  var pollOptions = [self.sm.get('accordion_option_yes'), self.sm.get('accordion_option_no'), self.sm.get('accordion_option_maybe')];

  self.accordionPoll.startPoll(votedMessageAuthor.id.toString());

  var createdPoll = await self.telegram.sendPoll(
    self.chatId,
    self.sm.get('accordion_vote_title'),
    pollOptions,
    explanation: self.sm.get('accordion_explanation'),
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
      VoteOption.yes: poll.options[0].voterCount,
      VoteOption.no: poll.options[1].voterCount,
      VoteOption.maybe: poll.options[2].voterCount
    };

    self.accordionPoll.voteResult = currentPollResults;
  });

  await Future.delayed(Duration(seconds: pollTime));

  var voteResult = self.accordionPoll.endVoteAndGetResults();

  await self.telegram.sendMessage(self.chatId, voteResult);
  await pollSubscription.cancel();
}

Future<void> getConversatorReply(TelegramBot self, TeleDartMessage message) async {
  var question = getFullMessageText(message);
  var reply = await self.conversator.getConversationReply(question);

  await message.reply(reply);
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
    await message.reply('User added');
  } else {
    await message.reply('User not added');
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
    await message.reply('User removed');
  } else {
    await message.reply('User not removed');
  }
}

Future<void> initChat(TelegramBot self, TeleDartMessage message) async {
  var chatId = message.chat.id.toString();
  var chatName = message.chat.title.toString();

  var result = await self.chatManager.createChat(id: chatId, name: chatName);

  if (result) {
    await message.reply('Chat initialized successfully');
  } else {
    await message.reply("Chat hasn't been initialized");
  }
}

Future<void> createReputation(TelegramBot self, TeleDartMessage message) async {
  var chatId = message.chat.id.toString();
  var userId = message.replyToMessage?.from?.id;

  if (userId == null) {
    await message.reply('User not selected');
  }

  var result = await self.reputation.createReputationData(chatId, userId.toString());

  if (result) {
    await message.reply('Created');
  } else {
    await message.reply('Not created');
  }
}
