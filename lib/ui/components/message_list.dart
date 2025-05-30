import 'package:flutter/material.dart';
import '../../repositories/backend/models/message.dart';
import 'message_user.dart';
import 'message_ai.dart';
import '../constants/dimensions/message_dimensions.dart';
import '../constants/app_colors.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final Function(Message) onTtsPlay;

  const MessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.onTtsPlay,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageWidget(context, message);
      },
    );
  }

  Widget _buildMessageWidget(BuildContext context, Message message) {
    final isUser = message.role == Message.ROLE_USER;

    if (isUser) {
      return MessageUser(content: message.content);
    } else {
      // Parse message content for special types
      Map<String, dynamic>? parsedContent;
      try {
        if (message.content.startsWith('{')) {
          parsedContent = Map<String, dynamic>.from(message.content as Map);
        } else {
          parsedContent = {'text': message.content};
        }
      } catch (e) {
        parsedContent = {'text': message.content};
      }

      return AssistantMessage(
        message: parsedContent['text'] ?? message.content,
        type: parsedContent['type'] ?? 'text',
        actions:
            parsedContent['actions'] != null
                ? List<Map<String, String>>.from(parsedContent['actions'])
                : null,
        card:
            parsedContent['card'] != null
                ? Map<String, String>.from(parsedContent['card'])
                : null,
        timestamp: parsedContent['timestamp'],
        onTtsPlay: () => onTtsPlay(message),
        isStreaming: message.id == 'streaming',
      );
    }
  }
}
