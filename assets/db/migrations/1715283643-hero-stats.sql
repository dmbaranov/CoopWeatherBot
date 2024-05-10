CREATE TABLE IF NOT EXISTS hero_stats
(
    id          SERIAL PRIMARY KEY,
    chat_id     VARCHAR(255) NOT NULL,
    bot_user_id VARCHAR(255) NOT NULL,
    timestamp   TIMESTAMP    NOT NULL
);