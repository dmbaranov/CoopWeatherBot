UPDATE weather
SET notification_hour = @notificationHour
WHERE chat_id = @chatId;
