SELECT id, name, chat_id, is_premium
FROM bot_user
WHERE deleted = FALSE
  AND chat_id = @chatId
  AND id = @userId;
