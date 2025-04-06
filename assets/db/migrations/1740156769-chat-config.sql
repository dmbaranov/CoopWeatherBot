CREATE TABLE IF NOT EXISTS chat_config
(
    id      SERIAL PRIMARY KEY,
    chat_id VARCHAR(255) NOT NULL,
    config  TEXT         NOT NULL DEFAULT '{}',
    CONSTRAINT fk_chat_config_chat_id FOREIGN KEY (chat_id) REFERENCES chat (id)
);
