INSERT INTO commands_statistics(bot_user_id, platform, command, timestamp)
VALUES (@userId, @platform, @command, @timestamp)
ON CONFLICT DO NOTHING;
