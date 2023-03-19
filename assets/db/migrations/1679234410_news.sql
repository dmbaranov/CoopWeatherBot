CREATE TABLE IF NOT EXISTS news
(
    id       SERIAL PRIMARY KEY,
    chat_id  VARCHAR(255) NOT NULL,
    news_url VARCHAR(255) NOT NULL,
    CONSTRAINT fk_weather_chat_id FOREIGN KEY (chat_id) REFERENCES chat (id)
);
