INSERT INTO conversator_chat(chat_id, conversation_id, message_id, message, from_user)
VALUES (@chatId, @conversationId, @messageId, @message, @fromUser)
ON CONFLICT DO NOTHING;
