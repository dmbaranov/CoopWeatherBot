CREATE TABLE IF NOT EXISTS commands_statistics
(
    id          SERIAL PRIMARY KEY,
    chat_id     VARCHAR(255) NOT NULL,
    bot_user_id VARCHAR(255) NOT NULL,
    command     VARCHAR(255) NOT NULL,
    timestamp   TIMESTAMP    NOT NULL,
    CONSTRAINT fk_commands_statistics_bot_user_id FOREIGN KEY (bot_user_id) REFERENCES bot_user (id),
    CONSTRAINT fk_commands_statistics_chat_id FOREIGN KEY (chat_id) REFERENCES chat (id)
);
