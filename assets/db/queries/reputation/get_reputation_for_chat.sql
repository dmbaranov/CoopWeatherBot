SELECT bot_user.name, reputation.reputation, bot_user
FROM reputation
         INNER JOIN bot_user ON reputation.bot_user_id = bot_user.id
WHERE reputation.chat_id = @chatId
ORDER BY reputation;
