UPDATE chat_member
SET deleted = TRUE
WHERE bot_user_id = @userId
  AND chat_id = @chatId;
