INSERT INTO bot_user(id, chat_id, name, is_premium)
VALUES (@id, @chatId, @name, @isPremium)
ON CONFLICT (id,chat_id)
    DO UPDATE SET deleted = FALSE;
