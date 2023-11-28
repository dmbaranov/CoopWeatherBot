SELECT command, COUNT(command)
FROM command_statistics
WHERE chat_id = @chatId
GROUP BY command
ORDER BY COUNT(command) DESC;
