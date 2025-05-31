import 'package:flutter/material.dart';
import '../components/messages/message_list.dart';

class ChatScreen extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  const ChatScreen({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    // 디버깅을 위한 메시지 출력
    debugPrint('ChatScreen - 메시지 개수: ${messages.length}');
    return messages.isEmpty
        ? const Center(child: Text('메시지가 없습니다.'))
        : ChatMessageList(messages: messages);
  }
}
