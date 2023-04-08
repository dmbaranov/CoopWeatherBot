INSERT INTO reputation(bot_user_id, chat_id, increase_options_left, decrease_options_left, reputation)
VALUES (@userId, @chatId, @increaseOptionsLeft, @decreaseOptionsLeft, 0)
ON CONFLICT DO NOTHING;
