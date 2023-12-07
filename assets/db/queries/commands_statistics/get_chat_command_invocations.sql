SELECT command, COUNT(command) AS invocations
FROM command_statistics
WHERE chat_id = @chatId
GROUP BY command
ORDER BY invocations DESC;
