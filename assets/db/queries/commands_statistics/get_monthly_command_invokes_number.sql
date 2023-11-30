SELECT COUNT(command)
FROM command_statistics
WHERE timestamp BETWEEN date_trunc('month', current_date - interval '1 month') AND date_trunc('month', current_date)
  AND chat_id = @chatId;