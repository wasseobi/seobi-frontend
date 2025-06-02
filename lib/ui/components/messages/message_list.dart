import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'dart:async'; // Timer 사용을 위해 추가
import 'user/user_message.dart';
import 'assistant/assistant_message.dart';
import 'message_list_view_model.dart';
import '../common/scroll_to_bottom_button.dart'; // 새로운 버튼 위젯 임포트

class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final ScrollController _scrollController = ScrollController();
  late KeyboardVisibilityController _keyboardVisibilityController;
  bool _showScrollToBottomButton = false;
  Timer? _scrollButtonTimer; // 디바운싱을 위한 타이머 추가

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
    _scrollButtonTimer?.cancel(); // 타이머 해제
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
    
    // 디바운싱 처리 - 마지막 스크롤 이벤트로부터 200ms 후에 버튼 상태 업데이트
    _scrollButtonTimer?.cancel();
    _scrollButtonTimer = Timer(const Duration(milliseconds: 200), () {
      _updateScrollToBottomButtonVisibility();
    });
  }
  
  /// 스크롤 위치에 따라 맨 아래로 내려가기 버튼 표시 여부를 업데이트
  void _updateScrollToBottomButtonVisibility() {
    if (!_scrollController.hasClients) return;
    
    const threshold = 150.0; // 스크롤이 맨 아래에서 150픽셀 이상 떨어지면 버튼 표시 (버퍼 증가)
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final isAtBottom = maxScroll - currentScroll <= threshold;
    
    final shouldShowButton = !isAtBottom && maxScroll > 0;
    
    // 상태가 실제로 변경될 때만 setState() 호출
    if (_showScrollToBottomButton != shouldShowButton && mounted) {
      setState(() {
        _showScrollToBottomButton = shouldShowButton;
      });
    }
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
    
    // 스크롤 후 버튼 숨기기
    if (_showScrollToBottomButton) {
      setState(() {
        _showScrollToBottomButton = false;
      });
    }
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

        return Stack(
          children: [
            ListView.separated(
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
            ),
            
            // 맨 아래로 내려가기 버튼
            Positioned(
              right: 16,
              bottom: 16,
              child: ScrollToBottomButton(
                visible: _showScrollToBottomButton && messages.isNotEmpty,
                onPressed: () => _scrollToBottom(),
              ),
            ),
          ],
        );
      },
    );
  }
}
