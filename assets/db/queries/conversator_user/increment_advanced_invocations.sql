UPDATE conversator_user
SET daily_advanced_invocations = daily_advanced_invocations + 1,
    total_advanced_invocations = total_advanced_invocations + 1
WHERE bot_user_id = @userId;
