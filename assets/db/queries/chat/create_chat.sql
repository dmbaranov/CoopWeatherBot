INSERT INTO chat(id, name, platform, swearwords_config)
VALUES (@chatId, @name, @platform, @swearwordsConfig)
ON CONFLICT DO NOTHING;
