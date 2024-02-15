SELECT id, chat_id, bot_user_id, message, timestamp
FROM check_reminder
WHERE completed = FALSE
ORDER BY timestamp
LIMIT @remindersLimit;