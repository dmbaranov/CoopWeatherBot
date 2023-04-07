SELECT id, name, chat_id, is_premium
FROM bot_user
WHERE chat_id = @chatId;
