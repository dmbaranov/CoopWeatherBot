SELECT bot_user.name, command, COUNT(command) AS invocations
FROM command_statistics
         INNER JOIN bot_user ON command_statistics.bot_user_id = bot_user.id
WHERE bot_user_id = @userId
GROUP BY command, bot_user.id
ORDER BY invocations DESC;