SELECT message, from_user
FROM conversator_chat
WHERE chat_id = @chatId
  AND conversation_id = @conversationId;
