INSERT INTO chat(id, name)
VALUES (@id, @name)
ON CONFLICT DO NOTHING;
