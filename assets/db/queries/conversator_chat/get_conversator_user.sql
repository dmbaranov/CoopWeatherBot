SELECT bot_user_id,
       daily_regular_invocations,
       total_regular_invocations,
       daily_advanced_invocations,
       total_advanced_invocations
FROM conversator_user
WHERE bot_user_id = @chatId;
