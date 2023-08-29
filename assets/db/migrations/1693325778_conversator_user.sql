CREATE TABLE IF NOT EXISTS conversator_user
(
    bot_user_id                VARCHAR(255) PRIMARY KEY,
    daily_regular_invocations  INT NOT NULL DEFAULT 0,
    total_regular_invocations  INT NOT NULL DEFAULT 0,
    daily_advanced_invocations INT NOT NULL DEFAULT 0,
    total_advanced_invocations INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_conversator_user_bot_user_id FOREIGN KEY (bot_user_id) REFERENCES bot_user (id)
);
