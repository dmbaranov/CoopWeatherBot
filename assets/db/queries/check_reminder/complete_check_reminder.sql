UPDATE check_reminder
SET completed = TRUE
WHERE id = @checkReminderId;