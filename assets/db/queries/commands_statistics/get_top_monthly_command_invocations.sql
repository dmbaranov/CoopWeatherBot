SELECT command,
       COUNT(command),
       COUNT(command) * 100 / (SELECT DISTINCT COUNT(command)
                               FROM command_statistics
                               WHERE timestamp BETWEEN date_trunc('month', current_date - interval '1 month') AND date_trunc('month', current_date)
                                 AND chat_id = @chatId) as percentage
FROM command_statistics
WHERE timestamp BETWEEN date_trunc('month', current_date - interval '1 month') AND date_trunc('month', current_date)
  AND chat_id = @chatId
GROUP BY command
ORDER BY COUNT(command) DESC
LIMIT 3;

