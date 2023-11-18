CREATE TABLE IF NOT EXISTS commands_statistics
(
    id          SERIAL PRIMARY KEY,
    bot_user_id VARCHAR(255) NOT NULL,
    platform    VARCHAR(255) NOT NULL,
    command     VARCHAR(255) NOT NULL,
    timestamp   TIMESTAMP    NOT NULL,
    CONSTRAINT fk_commands_statistics_bot_user_id FOREIGN KEY (bot_user_id) REFERENCES bot_user (id)
);
