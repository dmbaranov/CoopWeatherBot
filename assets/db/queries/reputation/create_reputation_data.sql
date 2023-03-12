INSERT INTO reputation(bot_user_id, chat_id, reputation, increase_options_left, decrease_options_left)
SELECT @userId, @chatId, 0, @increaseOptionsLeft, @decreaseOptionsLeft
WHERE EXISTS(SELECT id, chat_id FROM bot_user WHERE id = @userId AND chat_id = @chatId)
ON CONFLICT DO NOTHING;
