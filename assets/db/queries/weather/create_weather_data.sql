INSERT INTO weather(chat_id, notification_hour)
SELECT @chatId, @notificationHour
WHERE EXISTS(SELECT * FROM chat WHERE chat.id = @chatId)
ON CONFLICT DO NOTHING;
