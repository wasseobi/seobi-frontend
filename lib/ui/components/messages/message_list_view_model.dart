import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:seobi_app/services/conversation/history_service.dart';
import 'package:seobi_app/services/conversation/models/session.dart';
import 'package:seobi_app/services/conversation/models/message.dart';
import 'package:seobi_app/repositories/local_database/models/message_role.dart';
import 'assistant/message_types.dart';

/// 리스트 아이템의 기본 추상 클래스
abstract class ListItem {}

/// 메시지 아이템
class MessageItem extends ListItem {
  final Message message;
  final String sessionId;
  
  MessageItem({required this.message, required this.sessionId});
}

/// 세션 구분선 아이템
class SessionDividerItem extends ListItem {
  final String sessionId;
  final String? sessionTitle;
  
  SessionDividerItem({required this.sessionId, this.sessionTitle});
}

/// 세션 요약 아이템 (종료된 세션에 표시)
class SessionSummaryItem extends ListItem {
  final String sessionId;
  final String? title;
  final String? description;
  final DateTime? startAt;
  final DateTime? finishAt;
  
  SessionSummaryItem({
    required this.sessionId,
    this.title,
    this.description,
    this.startAt,
    this.finishAt,
  });
}

/// 대기 중인 사용자 메시지 아이템
class PendingUserMessageItem extends ListItem {
  final String content;
  
  PendingUserMessageItem({required this.content});
}

/// 메시지 리스트 뷰모델
class MessageListViewModel extends ChangeNotifier {
  final HistoryService _historyService = HistoryService();
  
  List<ListItem> _flattenedList = [];
  bool _isLoading = false;
  bool _isAnchored = true; // 스크롤이 맨 아래에 고정되어 있는지
  String? _error;
  
  // 자동 스크롤을 위한 콜백
  VoidCallback? _onShouldScrollToBottom;
  
  /// 평면화된 리스트 아이템들
  List<ListItem> get flattenedList => List.unmodifiable(_flattenedList);
  
  /// 로딩 상태
  bool get isLoading => _isLoading;
  
  /// 앵커 상태 (맨 아래 고정 여부)
  bool get isAnchored => _isAnchored;
  
  /// 에러 메시지
  String? get error => _error;
  
  /// 자동 스크롤 콜백 설정
  void setScrollToBottomCallback(VoidCallback? callback) {
    _onShouldScrollToBottom = callback;
  }
  
  /// UI 호환성을 위한 messages getter (기존 코드와의 호환성)
  List<Map<String, dynamic>> get messages {
    return _flattenedList
        .whereType<MessageItem>()
        .map((item) => {
          'isUser': item.message.role == MessageRole.user,
          'text': item.message.fullContent,
          'messageType': _extractUIMessageType(item.message),
          'timestamp': _formatUITimestamp(item.message.timestamp),
          'actions': item.message.extensions?['actions'],
          'card': item.message.extensions?['card'],
          'id': item.message.id,
          'sessionId': item.message.sessionId,
        })
        .toList();
  }

  /// UI 호환성을 위한 MessageType 추출
  MessageType _extractUIMessageType(Message message) {
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

  /// UI 호환성을 위한 타임스탬프 포맷팅
  String _formatUITimestamp(DateTime timestamp) {
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
  MessageListViewModel() {
    // HistoryService의 변화 감지
    _historyService.addListener(_onHistoryServiceChanged);
    _initialize();
  }

  @override
  void dispose() {
    _historyService.removeListener(_onHistoryServiceChanged);
    super.dispose();
  }
  /// HistoryService 변화 처리
  void _onHistoryServiceChanged() {
    debugPrint('[MessageListViewModel] HistoryService 변화 감지 - 리빌드 시작');
    _rebuildFlattenedList();
    debugPrint('[MessageListViewModel] HistoryService 변화 처리 완료 - notifyListeners 호출');
    notifyListeners();
  }
  /// 초기화
  Future<void> _initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _historyService.initialize();
      _rebuildFlattenedList();
      
      debugPrint('[MessageListViewModel] 초기화 완료');
    } catch (e) {
      _error = '메시지를 불러오는 중 오류가 발생했습니다: $e';
      debugPrint('[MessageListViewModel] 초기화 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 더 많은 세션 로드
  Future<void> loadMoreSessions({int count = 5}) async {
    if (!_historyService.hasMoreSessions || _isLoading) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _historyService.fetchPaginatedSessions(count);
      _rebuildFlattenedList();
      
    } catch (e) {
      _error = '추가 메시지를 불러오는 중 오류가 발생했습니다: $e';
      debugPrint('[MessageListViewModel] 추가 로딩 오류: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }  /// 평면화된 리스트 재구성
  void _rebuildFlattenedList() {
    debugPrint('[MessageListViewModel] 평면화된 리스트 재구성 시작');
    final result = <ListItem>[];
    final sessions = _historyService.sessions;
    
    debugPrint('[MessageListViewModel] 총 세션 수: ${sessions.length}');
    
    // 오래된 세션부터 처리하기 위해 순서를 뒤집음
    final reversedSessions = sessions.reversed.toList();
    
    for (int i = 0; i < reversedSessions.length; i++) {
      final session = reversedSessions[i];
      
      debugPrint('[MessageListViewModel] 세션 처리: ${session.id}, 로드됨: ${session.isLoaded}, 메시지 수: ${session.messages.length}');
      
      // 로드되지 않았거나 메시지가 없는 세션은 스킵
      if (!session.isLoaded || session.messages.isEmpty) {
        debugPrint('[MessageListViewModel] 세션 스킵: ${session.id}');
        continue;
      }
      
      // 세션의 메시지들을 시간순으로 추가 (오래된 것 → 최신)
      final sortedMessages = List<Message>.from(session.messages);
      sortedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      debugPrint('[MessageListViewModel] 세션 ${session.id}에서 ${sortedMessages.length}개 메시지 추가');
      
      result.addAll(
        sortedMessages.map(
          (message) => MessageItem(
            message: message,
            sessionId: session.id,
          ),
        ),
      );
      
      // 종료된 세션인 경우 세션 요약 정보 추가
      if (session.isFinished) {
        result.add(SessionSummaryItem(
          sessionId: session.id,
          title: session.title,
          description: session.description,
          startAt: session.startAt,
          finishAt: session.finishAt,
        ));
      }
      
      // 마지막 세션이 아니면 구분선 추가
      if (i < reversedSessions.length - 1) {
        result.add(SessionDividerItem(
          sessionId: session.id,
          sessionTitle: session.title,
        ));
      }
    }
    
    // 대기 중인 사용자 메시지가 있으면 최신 메시지로 추가
    final pendingMessage = _historyService.pendingUserMessage;
    if (pendingMessage != null && pendingMessage.isNotEmpty) {
      result.add(PendingUserMessageItem(content: pendingMessage));
      debugPrint('[MessageListViewModel] 대기 중인 메시지 추가: $pendingMessage');
    }
    
    _flattenedList = result;
    debugPrint('[MessageListViewModel] 평면화된 리스트 재구성 완료: ${result.length}개 아이템');
    
    // 앵커 상태가 true이면 자동으로 스크롤
    if (_isAnchored) {
      _onShouldScrollToBottom?.call();
    }
  }/// 새로고침
  Future<void> refresh() async {
    await _historyService.refresh();
    _historyService.resetOffset();
    _rebuildFlattenedList();
  }
  /// Pull-to-refresh로 추가 세션 로드
  Future<void> pullToRefresh() async {
    debugPrint('[MessageListViewModel] Pull-to-refresh 시작');
    await loadMoreSessions();
    debugPrint('[MessageListViewModel] Pull-to-refresh 완료');
  }

  /// 스크롤 앵커 상태 업데이트
  void updateAnchoredState(ScrollController scrollController) {
    if (!scrollController.hasClients) return;
    
    const threshold = 50.0;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.offset;
    final isAtBottom = maxScroll - currentScroll <= threshold;
    
    if (_isAnchored != isAtBottom) {
      _isAnchored = isAtBottom;
      notifyListeners();
    }
  }

  /// 앵커 상태 설정
  void setAnchored(bool anchored) {
    if (_isAnchored != anchored) {
      _isAnchored = anchored;
      notifyListeners();
    }
  }

  /// 특정 인덱스의 메시지 가져오기 (UI 호환성)
  Map<String, dynamic>? getMessageAtIndex(int index) {
    if (index < 0 || index >= messages.length) return null;
    return messages[index];
  }

  /// 메시지가 사용자 메시지인지 확인 (UI 호환성)
  bool isUserMessage(Map<String, dynamic> message) {
    return message['isUser'] as bool? ?? false;
  }
  /// 메시지 타입 가져오기 (UI 호환성)
  MessageType getMessageType(Map<String, dynamic> message) {
    return message['messageType'] as MessageType? ?? MessageType.text;
  }

  /// 더 불러올 세션이 있는지 확인
  bool get hasMoreSessions => _historyService.hasMoreSessions;

  /// 현재 로드된 세션 수
  int get loadedSessionCount => _historyService.sessions.length;

  /// 특정 세션 ID의 세션 찾기
  Session? getSessionById(String sessionId) {
    return _historyService.getSessionById(sessionId);
  }
}