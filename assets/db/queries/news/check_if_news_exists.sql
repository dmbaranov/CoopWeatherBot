SELECT id
FROM news
WHERE chat_id = @chatId
  AND news_url = @newsUrl;
