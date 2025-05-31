import 'package:flutter/material.dart';
import '../components/message_list.dart';

class ChatScreen extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  const ChatScreen({super.key, this.messages = const []});

  @override
  Widget build(BuildContext context) {
    return ChatMessageList(messages: messages);
  }
}
