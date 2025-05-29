import 'package:flutter/material.dart';
import 'message_user.dart';
import 'message_ai.dart';
import '../constants/dimensions/message_dimensions.dart';

class ChatMessageList extends StatelessWidget {
  final List<Map<String, dynamic>> messages; // 나중에 map에서 모델로 변경 예정

  const ChatMessageList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80, top: 16),
      itemCount: messages.length,
      reverse: false,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final msg = messages[index];
        final isUser = msg['isUser'] as bool;

        final messageWidget =
            isUser
                ? UserMessage(
                  key: ValueKey('user_$index'),
                  message: msg['text'],
                  isSentByUser: true,
                )
                : Padding(
                  padding:
                      msg['type'] == 'card' || msg['actions'] != null
                          ? EdgeInsets.only(left: MessageDimensions.padding)
                          : EdgeInsets.zero,
                  child: AssistantMessage(
                    key: ValueKey('ai_$index'),
                    message: msg['text'],
                    type: msg['type'], // 'text', 'action', 'card'
                    actions: msg['actions'], // optional
                    card: msg['card'], // optional
                    timestamp: msg['timestamp'], // optional
                  ),
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
  }
}
