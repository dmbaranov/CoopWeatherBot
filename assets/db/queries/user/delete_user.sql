UPDATE "user"
SET deleted = TRUE
WHERE id = @id;
