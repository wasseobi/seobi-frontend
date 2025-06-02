import 'package:flutter/material.dart';
import '../components/messages/message_list.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MessageList();
  }
}
