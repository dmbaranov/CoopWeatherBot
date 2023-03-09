UPDATE bot_user
SET deleted = TRUE
WHERE id = @id;
