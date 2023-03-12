UPDATE reputation
SET increase_options_left = @increaseOptionsLeft,
    decrease_options_left = @decreaseOptionsLeft
WHERE bot_user_id = @userId
  AND chat_id = @chatId;
