SELECT bot_user.name, reputation.reputation
FROM reputation
         INNER JOIN bot_user ON reputation.bot_user_id = bot_user.id
         INNER JOIN chat_member
                    ON reputation.chat_id = chat_member.chat_id AND reputation.bot_user_id = chat_member.bot_user_id
WHERE reputation.chat_id = @chatId
  AND chat_member.deleted = FALSE
ORDER BY reputation;