INSERT INTO commands_statistics(chat_id, bot_user_id, command, timestamp)
VALUES (@chatId, @userId, @command, @timestamp)
ON CONFLICT DO NOTHING;
