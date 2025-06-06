import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'dart:async';
import 'user/user_message.dart';
import 'user/pending_user_message.dart';
import 'assistant/assistant_message.dart';
import 'assistant/message_types.dart';
import 'message_list_view_model.dart';
import 'session_divider.dart';
import 'session_summary.dart';
import '../common/scroll_to_bottom_button.dart';
import '../../../services/conversation/models/message.dart';
import '../../../repositories/local_database/models/message_role.dart';

class MessageList extends StatefulWidget {
  final MessageListViewModel? viewModel;
  
  const MessageList({
    super.key, 
    this.viewModel,
  });

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  late KeyboardVisibilityController _keyboardVisibilityController;
  bool _showScrollToBottomButton = false;
  Timer? _scrollButtonTimer;
  bool _scrollListenerAdded = false; // 스크롤 리스너 추가 여부 추적
  
  @override
  bool get wantKeepAlive => true; // 탭 전환 시에도 상태를 유지하도록 설정
  
  @override
  void initState() {
    super.initState();

    // 키보드 표시 감지 컨트롤러 초기화
    _keyboardVisibilityController = KeyboardVisibilityController();

    // 키보드 상태 변경 리스너 등록
    _keyboardVisibilityController.onChange.listen(_onKeyboardVisibilityChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollButtonTimer?.cancel();
    super.dispose();
  }  /// 키보드 표시 상태가 변경될 때 호출됨
  void _onKeyboardVisibilityChanged(bool isKeyboardVisible) {
    // Consumer에서 viewModel을 직접 전달받지 못하므로 여전히 Provider.of 사용
    // 하지만 try-catch로 안전하게 처리
    try {
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
    } catch (e) {
      debugPrint('[MessageList] Provider 접근 오류 (키보드): $e');
      // Provider가 아직 준비되지 않은 경우 무시하고 계속 진행
    }
  }/// 스크롤 이벤트 발생 시 호출됨
  void _onScroll([MessageListViewModel? viewModel]) {
    if (viewModel != null) {
      viewModel.updateAnchoredState(_scrollController);
    } else {
      try {
        final vm = Provider.of<MessageListViewModel>(context, listen: false);
        vm.updateAnchoredState(_scrollController);
      } catch (e) {
        debugPrint('[MessageList] Provider 접근 오류 (스크롤): $e');
        // Provider가 아직 준비되지 않은 경우 무시
      }
    }
    
    // 디바운싱 처리 - 마지막 스크롤 이벤트로부터 200ms 후에 버튼 상태 업데이트
    _scrollButtonTimer?.cancel();
    _scrollButtonTimer = Timer(const Duration(milliseconds: 200), () {
      _updateScrollToBottomButtonVisibility();
    });
  }
  
  /// 스크롤 위치에 따라 맨 아래로 내려가기 버튼 표시 여부를 업데이트
  void _updateScrollToBottomButtonVisibility() {
    if (!_scrollController.hasClients) return;
    
    const threshold = 150.0;
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
  }  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 사용 시 필수
    
    return ChangeNotifierProvider(
      // 위젯 생성 시 전달받은 ViewModel이 있으면 사용하고, 없으면 새로 생성
      create: (context) => widget.viewModel ?? MessageListViewModel(),
      child: Consumer<MessageListViewModel>(
        builder: (context, viewModel, child) {
          final flattenedList = viewModel.flattenedList;          // Provider가 생성된 후에 스크롤 리스너 등록 및 자동 스크롤 콜백 설정
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollListenerAdded) {
              _scrollController.addListener(() => _onScroll(viewModel));
              _scrollListenerAdded = true;
              
              // 자동 스크롤 콜백 등록 - 새 메시지가 추가될 때 자동으로 스크롤
              viewModel.setScrollToBottomCallback(() => _scrollToBottom());
            }
            if (viewModel.isAnchored && _scrollController.hasClients) {
              _scrollToBottom();
            }
          });

          debugPrint('MessageList - 리스트 아이템 개수: ${flattenedList.length}');

          // 로딩 상태 처리
          if (viewModel.isLoading && flattenedList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 에러 상태 처리
          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.refresh(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );          }

          return Stack(
            children: [              RefreshIndicator(
                onRefresh: () => viewModel.pullToRefresh(),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    // Pull-to-Refresh를 통해서만 추가 세션 로드하도록 변경
                    // 스크롤 위치 도달에 따른 자동 로딩 제거
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    itemCount: flattenedList.length + (viewModel.isLoading ? 1 : 0),
                    reverse: false,
                    itemBuilder: (context, index) {
                      // 로딩 인디케이터 표시
                      if (index == flattenedList.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final listItem = flattenedList[index];
                      
                      // 세션 구분선 처리
                      if (listItem is SessionDividerItem) {
                        return SessionDivider(
                          key: ValueKey('divider_${listItem.sessionId}'),
                          sessionId: listItem.sessionId,
                          sessionTitle: listItem.sessionTitle,
                        );
                      }
                      
                      // 세션 요약 처리
                      if (listItem is SessionSummaryItem) {
                        return SessionSummary(
                          key: ValueKey('summary_${listItem.sessionId}'),
                          sessionId: listItem.sessionId,
                          title: listItem.title,
                          description: listItem.description,
                          startAt: listItem.startAt,
                          finishAt: listItem.finishAt,
                        );
                      }
                        // 메시지 처리
                      if (listItem is MessageItem) {
                        final message = _messageToUIFormat(listItem.message);
                        final isUser = message['isUser'] as bool;

                        // 성능 최적화를 위해 메시지 유형에 따라 다른 위젯 사용
                        final messageWidget = isUser
                            ? UserMessage(
                                key: ValueKey('user_${listItem.message.id}'),
                                message: message['text'] as String? ?? '',
                                isSentByUser: true,
                              )
                            : AssistantMessage(
                                key: ValueKey('ai_${listItem.message.id}'),
                                message: message['text'] as String? ?? '',
                                type: viewModel.getMessageType(message),
                                actions: message['actions'],
                                card: message['card'],
                                timestamp: message['timestamp'] as String? ?? '',
                              );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 100),
                              transitionBuilder: (child, animation) => SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                              child: messageWidget,
                            ),
                          ),
                        );
                      }
                      
                      // 대기 중인 사용자 메시지 처리
                      if (listItem is PendingUserMessageItem) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 100),
                              transitionBuilder: (child, animation) => SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                              child: PendingUserMessage(
                                key: ValueKey('pending_${listItem.content}'),
                                message: listItem.content,
                              ),
                            ),
                          ),
                        );
                      }
                        // 알 수 없는 아이템 타입의 경우 빈 컨테이너 반환
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),              // 맨 아래로 내려가기 버튼 (중앙 위치)
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: ScrollToBottomButton(
                    visible: _showScrollToBottomButton && flattenedList.isNotEmpty,
                    onPressed: () => _scrollToBottom(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Message 객체를 UI 형태로 변환하는 헬퍼 메서드
  Map<String, dynamic> _messageToUIFormat(Message message) {
    return {
      'isUser': message.role == MessageRole.user,
      'text': message.fullContent,
      'messageType': _extractMessageType(message),
      'timestamp': _formatTimestamp(message.timestamp),
      'actions': message.extensions?['actions'],
      'card': message.extensions?['card'],
      'id': message.id,
      'sessionId': message.sessionId,
    };
  }

  /// 메시지에서 MessageType 추출
  MessageType _extractMessageType(Message message) {
    final typeString = message.extensions?['messageType'] as String?;
    
    switch (typeString) {
      case 'text':
        return MessageType.text;
      case 'action':
        return MessageType.action;
      case 'card':
        return MessageType.card;
      default:
        return MessageType.text;
    }
  }

  /// 타임스탬프 포맷팅
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
