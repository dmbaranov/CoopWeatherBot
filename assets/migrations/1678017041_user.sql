CREATE TABLE IF NOT EXISTS "user"
(
    id         VARCHAR(255) PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    is_premium BOOLEAN
);
