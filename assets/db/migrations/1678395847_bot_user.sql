CREATE TABLE IF NOT EXISTS bot_user
(
    id         VARCHAR(255) NOT NULL UNIQUE,
    name       VARCHAR(255) NOT NULL,
    chat_id    VARCHAR(255) NOT NULL,
    is_premium BOOLEAN      NOT NULL DEFAULT FALSE,
    deleted    BOOLEAN      NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id, chat_id),
    CONSTRAINT fk_bot_user_chat_id FOREIGN KEY (chat_id) REFERENCES chat (id)
);
