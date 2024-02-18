SELECT id, chat_id, bot_user_id, message, timestamp
FROM check_reminder
WHERE completed = FALSE
  AND timestamp < NOW() + INTERVAL '1 minute' * @timestampInterval
ORDER BY timestamp
LIMIT @remindersLimit;