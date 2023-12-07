SELECT bot_user_id, reputation, increase_options_left, decrease_options_left
FROM reputation
WHERE bot_user_id = @userId
  AND chat_id = @chatId;
