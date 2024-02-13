INSERT INTO check_reminder(chat_id, bot_user_id, message, timestamp, completed)
VALUES (@chatId, @userId, @message, @timestamp, false)
ON CONFLICT DO NOTHING;