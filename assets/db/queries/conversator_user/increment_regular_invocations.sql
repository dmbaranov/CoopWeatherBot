UPDATE conversator_user
SET daily_regular_invocations = daily_regular_invocations + 1,
    total_regular_invocations = total_regular_invocations + 1
WHERE bot_user_id = @userId;
