INSERT INTO chat(id, name, platform)
VALUES (@chatId, @name, @platform)
ON CONFLICT DO NOTHING;
