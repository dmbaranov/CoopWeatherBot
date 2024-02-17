SELECT id, chat_id, bot_user_id, message, timestamp
FROM check_reminder
WHERE completed = FALSE
  AND timestamp < NOW() + INTERVAL '1 minute' * @timestampLimit
ORDER BY timestamp
LIMIT @remindersLimit;