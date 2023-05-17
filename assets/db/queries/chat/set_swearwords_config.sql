UPDATE chat
SET swearwords_config = @config
WHERE id = @chatId;
