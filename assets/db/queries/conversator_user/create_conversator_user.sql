INSERT INTO conversator_user(bot_user_id, daily_regular_invocations, total_regular_invocations,
                             daily_advanced_invocations, total_advanced_invocations)
VALUES (@userId, 0, 0, 0, 0)
ON CONFLICT DO NOTHING;
