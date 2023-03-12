INSERT INTO chat(id, name)
VALUES (@chatId, @name)
ON CONFLICT DO NOTHING;
