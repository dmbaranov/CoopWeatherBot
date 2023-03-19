UPDATE bot_user
SET deleted = TRUE
WHERE id = @userId
  and chat_id = @chatId;
