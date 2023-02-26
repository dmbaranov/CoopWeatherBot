import 'dart:convert';
import 'dart:math';
import 'dart:io' as io;
import 'package:teledart/model.dart';
import 'package:weather/src/modules/accordion_poll.dart';

import './bot.dart';
import './utils.dart';

void addCity(TelegramBot self, TeleDartMessage message) async {
  var cityToAdd = getOneParameterFromMessage(message);

  var result = await self.weather.addCity(cityToAdd);

  if (result) {
    await message.reply('City $cityToAdd has been added to the watchlist!');
  } else {
    await message.reply('Error');
  }
}

void removeCity(TelegramBot self, TeleDartMessage message) async {
  var cityToRemove = getOneParameterFromMessage(message);

  var result = await self.weather.removeCity(cityToRemove);

  if (result) {
    await message.reply('City $cityToRemove has been removed from the watchlist!');
  } else {
    await message.reply('Error');
  }
}

void getWatchlist(TelegramBot self, TeleDartMessage message) async {
  var citiesString = await self.weather.getWatchList();

  await message.reply("I'm watching these cities:\n$citiesString");
}

void getWeatherForCity(TelegramBot self, TeleDartMessage message) async {
  var city = getOneParameterFromMessage(message);

  if (city.isEmpty) {
    await message.reply('Provide a city!');

    return;
  }

  var temperature = await self.weather.getWeatherForCity(city);

  if (temperature != null) {
    await message.reply('In city $city the temperature is $temperature°C');
  } else {
    await message.reply('There was an error processing your request! Try again');
  }
}

void setNotificationHour(TelegramBot self, TeleDartMessage message) async {
  var nextHour = getOneParameterFromMessage(message);

  var result = self.weather.setNotificationsHour(int.parse(nextHour));

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
    var temperature = await self.weather.getWeatherForCity(city);

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

  var rawText = message.text?.split(' ');
  var text = rawText?.sublist(1).join(' ') ?? '';

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
  var query = message.text?.split(' ').sublist(1).join(' ');

  if (query == null || query.isEmpty) {
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

Future<void> updateReputation(TelegramBot self, TeleDartMessage message, String change) async {
  if (message.replyToMessage == null) {
    await message.reply(self.sm.get('error_occurred'));

    return;
  }

  var fromId = message.from?.id.toString();
  var toId = message.replyToMessage?.from?.id.toString();

  var changeResult = await self.reputation.updateReputation(from: fromId, to: toId, type: change, isPremium: message.from?.isPremium);

  await self.telegram.sendMessage(self.chatId, changeResult);
}

Future<void> sendReputationList(TelegramBot self, TeleDartMessage message) async {
  var reputationMessage = self.reputation.getReputationMessage();

  await message.reply(reputationMessage);
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
