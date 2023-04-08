INSERT INTO chat_member
VALUES (@userId, @chatId)
ON CONFLICT (bot_user_id, chat_id) DO UPDATE SET deleted = FALSE;
