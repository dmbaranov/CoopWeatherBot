INSERT INTO news(chat_id, news_url)
VALUES (@chatId, @newsUrl)
ON CONFLICT DO NOTHING;
