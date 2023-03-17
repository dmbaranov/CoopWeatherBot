CREATE TABLE IF NOT EXISTS weather
(
    chat_id           VARCHAR(255) PRIMARY KEY,
    cities            TEXT,
    notification_hour INT NOT NULL,
    CONSTRAINT fk_weather_chat_id FOREIGN KEY (chat_id) REFERENCES chat (id)
);
