SELECT command,
       COUNT(command)                                   AS invocations,
       COUNT(command) * 100 / (SELECT DISTINCT COUNT(command)
                               FROM command_statistics
                               WHERE timestamp BETWEEN DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') AND DATE_TRUNC('month', CURRENT_DATE)
                                 AND chat_id = @chatId) AS percentage
FROM command_statistics
WHERE timestamp BETWEEN DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') AND DATE_TRUNC('month', CURRENT_DATE)
  AND chat_id = @chatId
GROUP BY command
ORDER BY invocations DESC
LIMIT 3;

