UPDATE reputation
SET reputation = @reputation
WHERE bot_user_id = @userId;
