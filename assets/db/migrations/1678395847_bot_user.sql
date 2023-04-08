CREATE TABLE IF NOT EXISTS bot_user
(
    id         VARCHAR(255) PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    is_premium BOOLEAN      NOT NULL DEFAULT FALSE
);
