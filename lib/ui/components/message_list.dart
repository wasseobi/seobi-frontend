import 'package:flutter/material.dart';
import 'messages/user/user_message.dart';
import 'messages/assistant/assistant_message.dart';
import 'messages/assistant/message_types.dart'; // MessageType enum import

class ChatMessageList extends StatelessWidget {
  final List<Map<String, dynamic>> messages; // 나중에 map에서 모델로 변경 예정

  const ChatMessageList({super.key, required this.messages});
  @override
  Widget build(BuildContext context) {
    debugPrint('ChatMessageList - 메시지 개수: ${messages.length}');
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
        final msg = messages[index];
        final isUser = msg['isUser'] as bool;

        // 성능 최적화를 위해 메시지 유형에 따라 다른 위젯 사용
        final messageWidget =
            isUser
                ? UserMessage(
                  key: ValueKey('user_$index'),
                  message: msg['text'],
                  isSentByUser: true,
                )
                : AssistantMessage(
                  key: ValueKey('ai_$index'),
                  message: msg['text'],
                  // 타입을 직접 MessageType enum으로 전달
                  // 기존 'text', 'action', 'card' 문자열 대신 enum을 보관하도록 데이터 모델 수정 필요
                  type: msg['messageType'] ?? MessageType.text,
                  actions: msg['actions'],
                  card: msg['card'],
                  timestamp: msg['timestamp'],
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
