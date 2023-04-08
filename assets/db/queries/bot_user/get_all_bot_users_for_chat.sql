SELECT id, name, is_premium, deleted, banned, moderator
FROM bot_user
         INNER JOIN chat_member cm on bot_user.id = cm.bot_user_id
WHERE chat_id = @chatId;
