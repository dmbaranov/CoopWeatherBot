CREATE TABLE IF NOT EXISTS check_reminder
(
    id          SERIAL PRIMARY KEY,
    chat_id     VARCHAR(255) NOT NULL,
    bot_user_id VARCHAR(255) NOT NULL,
    message     TEXT         NOT NULL,
    timestamp   TIMESTAMP    NOT NULL,
    completed   BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_check_reminder_chat_id FOREIGN KEY (chat_id) REFERENCES chat (id),
    CONSTRAINT fk_check_reminder_bot_user_id FOREIGN KEY (bot_user_id) REFERENCES bot_user (id)
);