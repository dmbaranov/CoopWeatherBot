SELECT command, count(command)
FROM commands_statistics
WHERE chat_id = @chatId
GROUP BY command
ORDER BY count(command) DESC;
