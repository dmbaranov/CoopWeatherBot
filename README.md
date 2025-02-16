~Simple bot to get the current weather and post it to Coop chat as requested from the member Denis Korshunov.~

# WeatherBot

Once started as a simple bot to automatically send out weather to the Telegram channel with friends, this bot has
evolved a lot ever since. Now available for Discord as well!

## Features

- Weather
    - Get timely notifications for the watchlist of cities;
    - Get the current weather for the city;
- News
    - Read latest morning, afternoon and evening news or get them whenever you want;
- YouTube
    - Search for videos on YouTube (originally planned to be used for songs, but who cares?!);
- ChatGPT
    - Have a question? Worry not, ChatGPT is here to help you! Ask single questions or have a conversation with it;
- Jokes
    - Feels like a bad day? Perhaps some jokes can make it better;
- Reputation
    - Particularly useful for the chats with friends, this module allows to increase or decrease reputation of the
      people. Use it wisely;
- Accordion votes
    - Someone has sent a message that has already been there? Start a vote to mark it as chestnut;
- Integrated admin panel with convenient UI to control the bot
    - Run [frontend](https://github.com/dmbaranov/weather-bot-admin-frontend)
      and [backend](https://github.com/dmbaranov/weather-bot-admin-backend) on-demand
- And some much more
    - And many more to come, stay tuned;

## How to start

If you want to try out this bot yourself, you'd need to have [Dart](https://dart.dev/)
and [PostgreSQL](https://www.postgresql.org/) installed and running. Once ready, follow these steps:

1. `cp .env.example .env`
2. Update variables in the .env file
3. `dart pub get`
3. `dart bin/main.dart`
