import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'user/user_message.dart';
import 'assistant/assistant_message.dart';
import 'message_list_view_model.dart';

class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  late KeyboardVisibilityController _keyboardVisibilityController;

  @override
  void initState() {
    super.initState();

    // 스크롤 이벤트 리스너 등록
    _scrollController.addListener(_onScroll);

    // 키보드 표시 감지 컨트롤러 초기화
    _keyboardVisibilityController = KeyboardVisibilityController();

    // 키보드 상태 변경 리스너 등록
    _keyboardVisibilityController.onChange.listen(_onKeyboardVisibilityChanged);

    // 첫 로드 시 스크롤 위치를 맨 아래로 설정 (약간의 지연 후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animate: false);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  /// 키보드 표시 상태가 변경될 때 호출됨
  void _onKeyboardVisibilityChanged(bool isKeyboardVisible) {
    final viewModel = Provider.of<MessageListViewModel>(
      context,
      listen: false,
    );

    debugPrint(
      '키보드 표시 상태 변경: $isKeyboardVisible, '
      'isAnchored: ${viewModel.isAnchored}',
    );
    
    if (isKeyboardVisible) {
      if (viewModel.isAnchored) {
        // 키보드가 완전히 올라온 후에 스크롤을 맨 아래로 이동 (300ms 지연)
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
    } else {
      // 키보드가 닫힌 후 300ms 지연 후 스크롤 위치 재점검
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          // 현재 스크롤 위치가 맨 아래인지 확인
          const threshold = 20.0;
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.offset;
          final isAtBottom = maxScroll - currentScroll <= threshold;
          
          // 맨 아래에 위치한 경우 isAnchored를 true로 설정
          if (isAtBottom && !viewModel.isAnchored) {
            viewModel.setAnchored(true);
            debugPrint('키보드 닫힘 후 스크롤 위치 확인: 맨 아래 위치, isAnchored = true로 설정');
          }
        }
      });
    }
  }

  /// 스크롤 이벤트 발생 시 호출됨
  void _onScroll() {
    final viewModel = Provider.of<MessageListViewModel>(context, listen: false);
    viewModel.updateAnchoredState(_scrollController);
  }

  /// 스크롤을 맨 아래로 이동
  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final duration =
        animate ? const Duration(milliseconds: 100) : Duration.zero;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: duration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessageListViewModel>(
      builder: (context, viewModel, child) {
        final messages = viewModel.messages;

        debugPrint('MessageList - 메시지 개수: ${messages.length}');

        // 이전 메시지 수와 현재 메시지 수를 비교하여 새 메시지가 추가된 경우
        // isAnchored가 true면 스크롤을 맨 아래로 이동
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (viewModel.isAnchored && _scrollController.hasClients) {
            _scrollToBottom();
          }
        });

        return ListView.separated(
          controller: _scrollController,
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
            final message = viewModel.getMessageAtIndex(index) ?? {};
            final isUser = viewModel.isUserMessage(message);

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
                      type: viewModel.getMessageType(message),
                      actions: message['actions'],
                      card: message['card'],
                      timestamp: message['timestamp'] as String? ?? '',
                    );

            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
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
