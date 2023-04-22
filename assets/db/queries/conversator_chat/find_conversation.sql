SELECT conversation_id
FROM conversator_chat
WHERE chat_id = @chatId
  AND message_id = @messageId;
