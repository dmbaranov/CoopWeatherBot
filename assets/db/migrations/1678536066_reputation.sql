CREATE TABLE IF NOT EXISTS reputation
(
    bot_user_id           VARCHAR(255) NOT NULL,
    chat_id               VARCHAR(255) NOT NULL,
    increase_options_left INT          NOT NULL,
    decrease_options_left INT          NOT NULL,
    reputation            INT          NOT NULL DEFAULT 0,
    CONSTRAINT fk_reputation_bot_user_id FOREIGN KEY (bot_user_id) REFERENCES bot_user (id),
    CONSTRAINT fk_reputation_chat_id FOREIGN KEY (chat_id) REFERENCES chat (id),
    PRIMARY KEY (bot_user_id, chat_id)
);
