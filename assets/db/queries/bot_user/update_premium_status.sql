UPDATE bot_user
SET is_premium = @isPremium
WHERE id = @userId;
