SELECT bot_user.name, reputation.reputation, bot_user.chat_id
FROM reputation
         INNER JOIN bot_user ON reputation.bot_user_id = bot_user.id AND reputation.chat_id = bot_user.chat_id
WHERE reputation.chat_id = @chatId
ORDER BY reputation;
