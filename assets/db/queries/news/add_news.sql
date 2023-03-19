INSERT INTO news(chat_id, news_url)
SELECT @chatId, @newsUrl
WHERE EXISTS(SELECT * FROM chat WHERE chat.id = @chatId)
ON CONFLICT DO NOTHING;
