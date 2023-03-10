INSERT INTO bot_user (id, chat_id, name, is_premium)
SELECT @id, @chatId, @name, @isPremium
WHERE EXISTS(SELECT * FROM chat WHERE chat.id = @chatId)
ON CONFLICT (id,chat_id) DO UPDATE SET deleted = FALSE;
