import 'package:flutter/material.dart';
import '../chat/chat_view.dart';
import '../../services/conversation/conversation_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final ConversationService _conversationService = ConversationService();
  String? sessionId;

  void startSession() async {
    try {
      final session = await _conversationService.createSession();
      setState(() {
        sessionId = session.id;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('세션 시작 실패: $e')),
        );
      }
    }
  }

  void endSession() {
    if (sessionId == null) return;

    _conversationService.endSession(sessionId!).then((_) {
      setState(() {
        sessionId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('세션 종료 완료')),
      );
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('세션 종료 실패: $e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('디버그'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: sessionId == null ? startSession : null,
                  child: const Text('세션 시작'),
                ),
                ElevatedButton(
                  onPressed: sessionId != null ? endSession : null,
                  child: const Text('세션 종료'),
                ),
              ],
            ),
          ),
          Expanded(
            child: sessionId != null 
              ? ChatView(sessionId: sessionId!)
              : const Center(child: Text('세션을 시작해주세요')),
          ),
        ],
      ),
    );
  }
}