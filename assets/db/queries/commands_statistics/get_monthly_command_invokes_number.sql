SELECT COUNT(command) AS invocations
FROM command_statistics
WHERE timestamp BETWEEN DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month') AND DATE_TRUNC('month', CURRENT_DATE)
  AND chat_id = @chatId;