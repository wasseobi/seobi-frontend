import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user/user_message.dart';
import 'assistant/assistant_message.dart';
import '../../utils/chat_provider.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.messages;

        debugPrint('ChatMessageList - ChatProvider 메시지 개수: ${messages.length}');

        return ListView.separated(
          padding: const EdgeInsets.only(
            bottom: 80,
            top: 16,
            left: 32,
            right: 32,
          ),
          itemCount: messages.length,
          reverse: false,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final message = messages[index];
            final isUser = message['isUser'] as bool? ?? false;

            // 성능 최적화를 위해 메시지 유형에 따라 다른 위젯 사용
            final messageWidget =
                isUser
                    ? UserMessage(
                      key: ValueKey('user_$index'),
                      message: message['text'] as String? ?? '',
                      isSentByUser: true,
                    )
                    : AssistantMessage(
                      key: ValueKey('ai_$index'),
                      message: message['text'] as String? ?? '',
                      type: message['messageType'],
                      actions: message['actions'],
                      card: message['card'],
                      timestamp: message['timestamp'] as String? ?? '',
                    );

            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, animation) => SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                child: messageWidget,
              ),
            );
          },
        );
      },
    );
  }
}
