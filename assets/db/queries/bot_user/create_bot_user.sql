INSERT INTO bot_user(id, name, is_premium)
VALUES (@userId, @name, @isPremium)
ON CONFLICT DO NOTHING;
