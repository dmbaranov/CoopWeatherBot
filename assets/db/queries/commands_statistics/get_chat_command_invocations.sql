SELECT command, COUNT(command)
FROM commands_statistics
WHERE chat_id = @chatId
GROUP BY command
ORDER BY COUNT(command) DESC;
