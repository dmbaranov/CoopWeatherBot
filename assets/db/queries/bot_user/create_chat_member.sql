INSERT INTO chat_member
VALUES (@userId, @chatId)
ON CONFLICT DO NOTHING;
