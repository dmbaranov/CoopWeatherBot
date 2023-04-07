CREATE TABLE chat_member
(
    bot_user_id VARCHAR(255) NOT NULL,
    chat_id     VARCHAR(255) NOT NULL,
    deleted     BOOLEAN      NOT NULL DEFAULT FALSE,
    banned      BOOLEAN      NOT NULL DEFAULT FALSE,
    moderator   BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_chat_member_bot_user_id FOREIGN KEY (bot_user_id) REFERENCES bot_user (id),
    CONSTRAINT fk_chat_member_chat_id FOREIGN KEY (chat_id) REFERENCES chat (id),
    PRIMARY KEY (bot_user_id, chat_id)
);
