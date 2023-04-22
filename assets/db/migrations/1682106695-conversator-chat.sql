CREATE TABLE conversator_chat
(
    id              SERIAL PRIMARY KEY,
    chat_id         VARCHAR(255) NOT NULL,
    conversation_id VARCHAR(255) NOT NULL,
    message_id      VARCHAR(255) NOT NULL,
    message         TEXT         NOT NULL,
    from_user       BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT fk_conversator_chat_id FOREIGN KEY (chat_id) REFERENCES chat (id)
);
