CREATE TABLE IF NOT EXISTS hero_stats
(
    id          SERIAL PRIMARY KEY,
    chat_id     VARCHAR(255) NOT NULL,
    bot_user_id VARCHAR(255) NOT NULL,
    timestamp   TIMESTAMP    NOT NULL,
    CONSTRAINT fk_hero_stats_chat_id FOREIGN KEY (chat_id) REFERENCES chat (id),
    CONSTRAINT fk_hero_stats_bot_user_id FOREIGN KEY (bot_user_id) REFERENCES bot_user (id)
);