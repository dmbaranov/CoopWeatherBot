SELECT bot_user_id, COUNT(bot_user_id) AS stats
FROM hero_stats
WHERE chat_id = @chatId
GROUP BY bot_user_id
HAVING COUNT(bot_user_id) >= 10
ORDER BY stats DESC;