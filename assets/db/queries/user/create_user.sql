INSERT INTO "user"(id, name, is_premium)
VALUES (@id, @name, @isPremium)
ON CONFLICT (id)
    DO UPDATE SET deleted = FALSE;
