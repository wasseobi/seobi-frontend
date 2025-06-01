import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user/user_message.dart';
import 'assistant/assistant_message.dart';
import 'message_list_view_model.dart';

class ChatMessageList extends StatelessWidget {
  const ChatMessageList({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        // 자체적으로 예시 메시지 생성하는 뷰모델 생성
        final viewModel = MessageListViewModel();
        return viewModel;
      },
      child: const _ChatMessageListView(),
    );
  }
}

/// 실제 메시지 목록 UI를 표시하는 내부 위젯
class _ChatMessageListView extends StatelessWidget {
  const _ChatMessageListView();
  
  @override
  Widget build(BuildContext context) {
    // Provider에서 ViewModel 가져오기
    final viewModel = context.watch<MessageListViewModel>();
    final messages = viewModel.messages;
    
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
        final message = messages[index];
        final isUser = message.isUser;

        // 성능 최적화를 위해 메시지 유형에 따라 다른 위젯 사용
        final messageWidget =
            isUser
                ? UserMessage(
                  key: ValueKey('user_$index'),
                  message: message.text,
                  isSentByUser: true,
                )
                : AssistantMessage(
                  key: ValueKey('ai_$index'),
                  message: message.text,
                  type: message.messageType,
                  actions: message.actions,
                  card: message.card,
                  timestamp: message.timestamp,
                );        return Align(
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
