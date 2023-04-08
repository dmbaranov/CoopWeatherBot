INSERT INTO weather(chat_id, notification_hour)
VALUES (@chatId, @notificationHour)
ON CONFLICT DO NOTHING;
