SELECT bot_user.name, COUNT(command) AS invocations
FROM command_statistics
         INNER JOIN bot_user ON command_statistics.bot_user_id = bot_user.id
WHERE timestamp BETWEEN DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') AND DATE_TRUNC('month', CURRENT_DATE)
  AND chat_id = @chatId
GROUP BY bot_user.name
ORDER BY invocations DESC
LIMIT 3;