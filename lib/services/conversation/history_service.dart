import 'package:flutter/foundation.dart';
import 'package:seobi_app/repositories/backend/backend_repository.dart';
import '../auth/auth_service.dart';
import 'models/session.dart';
import 'models/message.dart';

/// 대화 히스토리를 관리하는 서비스
class HistoryService extends ChangeNotifier {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;

  final BackendRepository _backendRepository = BackendRepository();
  final AuthService _authService = AuthService();

  /// 모든 세션 정보 (최신 → 오래된 순서)
  List<Session> _sessions = [];

  /// 페이지네이션용 오프셋
  int _offset = 0;

  /// 서버 응답 대기 중인 사용자 메시지 내용
  String? _pendingUserMessage;

  /// 현재 로그인된 사용자 ID
  String? _currentUserId;

  /// 초기화 완료 여부
  bool _isInitialized = false;

  HistoryService._internal() {
    // AuthService의 변화를 감지
    _authService.addListener(_onAuthStateChanged);
  }  /// 모든 세션 정보를 원격에서 가져와서 최신 → 오래된 순서로 저장
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[HistoryService] 이미 초기화됨');
      return;
    }

    try {
      // 인증 서비스 초기화
      await _authService.init();
      // 현재 사용자 정보 저장
      _currentUserId = _authService.userId;
      
      if (_currentUserId == null) {
        debugPrint('[HistoryService] 로그인되지 않은 상태로 초기화');
        _sessions = [];
        _offset = 0;
        _isInitialized = true;
        notifyListeners();
        return;
      }      // 사용자 인증 및 ID 가져오기
      final userId = await _getUserIdAndAuthenticate();
      
      if (userId == null) {
        debugPrint('[HistoryService] 인증 실패 - 세션 정보 클리어');
        _sessions = [];
        _offset = 0;
        _isInitialized = true;
        notifyListeners();
        return;
      }

      final backendSessions = await _backendRepository.getSessionsByUserId(userId);
      _sessions = backendSessions.map((s) => Session.fromBackendSession(s)).toList();
      _sessions.sort((a, b) {
        if (a.startAt == null || b.startAt == null) return 0;
        return b.startAt!.compareTo(a.startAt!);
      });

      _offset = 0;
      _isInitialized = true;

      debugPrint('[HistoryService] 초기화 완료 (총 ${_sessions.length}개 세션)');

      await _loadInitialSessions();
      notifyListeners();

    } catch (e) {
      debugPrint('[HistoryService] 초기화 오류: $e');
      if (e.toString().contains('Connection') || 
          e.toString().contains('ClientException') ||
          e.toString().contains('SocketException')) {
        debugPrint('[HistoryService] 네트워크 오류로 오프라인 모드 초기화');
        _sessions = [];
        _offset = 0;
        _isInitialized = true;
        notifyListeners();
        return;
      }
      rethrow;
    }
  }

  /// 인증 상태 변화 처리
  void _onAuthStateChanged() async {
    debugPrint('[HistoryService] 인증 상태 변화 감지');
    
    final newUserId = _authService.userId;
    
    // 사용자가 변경된 경우 (로그아웃, 다른 계정으로 로그인 등)
    if (_currentUserId != newUserId) {
      debugPrint('[HistoryService] 사용자 변경 감지: $_currentUserId -> $newUserId');
      
      _currentUserId = newUserId;
      _isInitialized = false;
      
      // 세션 정보 초기화
      _sessions.clear();
      _offset = 0;
      _pendingUserMessage = null;
        // 새로운 사용자로 다시 초기화
      if (newUserId != null) {
        try {
          await initialize();
        } catch (e) {
          debugPrint('[HistoryService] 사용자 변경 후 초기화 실패: $e');
          // 초기화 실패 시에도 빈 세션으로 유지
          _sessions = [];
          _offset = 0;
          _isInitialized = true;
          notifyListeners();
        }
      } else {
        // 로그아웃된 경우
        debugPrint('[HistoryService] 로그아웃됨 - 세션 정보 클리어');
        _isInitialized = true;
        notifyListeners();
      }
    }  }
  
  /// 현재 사용자 정보를 가져오고 인증을 설정합니다.
  /// 로그인이 안 되어 있으면 null을 반환합니다.
  Future<String?> _getUserIdAndAuthenticate() async {
    final user = await _authService.getUserInfo();
    if (user == null) {
      debugPrint('[HistoryService] 사용자가 로그인되지 않음');
      return null;
    }
    if (user.accessToken == null) {
      debugPrint('[HistoryService] 인증 토큰이 없음');
      return null;
    }

    // BackendRepository에 인증 토큰 설정
    _backendRepository.setAuthToken(user.accessToken);    return user.id;
  }

  /// 초기 세션들 로드 (첫 5개 세션)
  Future<void> _loadInitialSessions() async {
    try {
      if (_sessions.isEmpty) {
        debugPrint('[HistoryService] 로드할 세션 없음');
        return;
      }
      
      await fetchPaginatedSessions(5);
      debugPrint('[HistoryService] 초기 ${_offset}개 세션 로드 완료');
    } catch (e) {
      debugPrint('[HistoryService] 초기 세션 로드 실패: $e');
    }
  }

  /// 특정 세션의 메시지 리스트를 가져와서 채운 세션을 반환
  Future<Session> fetchSession(Session session) async {
    try {
      // 이미 로드된 세션이면 기존 세션 반환
      if (session.isLoaded) {
        return session;
      }

      final backendMessages = await _backendRepository.getMessagesBySessionId(session.id);
      final messages = backendMessages.map((m) {
        // 메시지 타입에 따른 처리
        var msg = Message.fromBackendMessage(m);
        
        // 도구 관련 메시지의 타입 확인 및 설정
        if (m.extensions != null) {
          if (m.extensions!['tool_calls'] != null) {
            msg = msg.copyWith(
              extensions: {
                'messageType': 'tool_calls',
                'tool_calls': m.extensions!['tool_calls'],
                ...?m.extensions!['metadata'],
              },
            );
          } else if (m.extensions!['messageType'] == 'toolmessage') {
            msg = msg.copyWith(
              extensions: {
                'messageType': 'toolmessage',
                ...?m.extensions!['metadata'],
              },
            );
          }
        }
        
        return msg;
      }).toList();
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final updatedSession = session.copyWith(
        messages: messages,
        isLoaded: true,
      );

      debugPrint('[HistoryService] 세션 ${session.id} 로드 완료: ${messages.length}개 메시지');
      return updatedSession;

    } catch (e) {
      debugPrint('[HistoryService] 세션 메시지 로드 오류: $e');
      if (e.toString().contains('Connection') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('SocketException')) {
        return session.copyWith(
          messages: <Message>[],
          isLoaded: true,
        );
      }
      rethrow;
    }
  }

  /// n개의 세션을 페이지네이션으로 가져와서 메시지까지 로드
  /// n은 메시지가 1개 이상 있는 세션의 개수를 의미함
  Future<void> fetchPaginatedSessions(int n) async {
    try {
      debugPrint('[HistoryService] 세션 로드 시작: offset=$_offset, 요청=$n');

      int loadedSessionsWithMessages = 0;
      int processedSessions = 0;
      
      while (loadedSessionsWithMessages < n && _offset + processedSessions < _sessions.length) {
        final sessionIndex = _offset + processedSessions;
        final session = _sessions[sessionIndex];

        try {
          final updatedSession = await fetchSession(session);
          _sessions[sessionIndex] = updatedSession;

          if (updatedSession.messages.isNotEmpty) {
            loadedSessionsWithMessages++;
          }
          processedSessions++;
        } catch (e) {
          _sessions[sessionIndex] = session.copyWith(
            messages: <Message>[],
            isLoaded: true,
          );
          processedSessions++;
        }
      }

      _offset += processedSessions;
      debugPrint('[HistoryService] 세션 로드 완료: 메시지 있는 세션 $loadedSessionsWithMessages/$processedSessions');
      notifyListeners();

    } catch (e) {
      debugPrint('[HistoryService] 페이지네이션 오류: $e');
      rethrow;
    }
  }

  /// 세션 업데이트 (메시지 추가/수정 시 사용)
  void updateSession(Session updatedSession) {
    final index = _sessions.indexWhere((s) => s.id == updatedSession.id);
    if (index != -1) {
      _sessions[index] = updatedSession;
      debugPrint('[HistoryService] 세션 업데이트: ${updatedSession.id} (${updatedSession.messages.length}개 메시지)');
      notifyListeners();
    }
  }

  /// 새 세션 추가
  void addSession(Session newSession) {
    _sessions.insert(0, newSession);
    debugPrint('[HistoryService] 새 세션 추가: ${newSession.id}');
    notifyListeners();
  }

  /// 세션 리스트 getter
  List<Session> get sessions => List.unmodifiable(_sessions);

  /// 현재 오프셋 값 getter
  int get currentOffset => _offset;

  /// 더 불러올 세션이 있는지 확인
  bool get hasMoreSessions => _offset < _sessions.length;

  /// 특정 ID의 세션 찾기
  Session? getSessionById(String sessionId) {
    try {
      return _sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  /// 세션 리스트 새로고침
  Future<void> refresh() async {
    await initialize();
  }

  /// 오프셋 리셋
  void resetOffset() {
    _offset = 0;
    debugPrint('[HistoryService] 오프셋 리셋');
  }
  /// 대기 중인 사용자 메시지 설정
  void setPendingUserMessage(String? message) {
    _pendingUserMessage = message;
    if (message != null) {
      debugPrint('[HistoryService] 대기 메시지 설정');
    }
    notifyListeners();
  }

  /// 대기 중인 사용자 메시지 조회
  String? get pendingUserMessage => _pendingUserMessage;

  /// 대기 중인 사용자 메시지 클리어
  void clearPendingUserMessage() {
    if (_pendingUserMessage != null) {
      debugPrint('[HistoryService] 대기 메시지 클리어');
      _pendingUserMessage = null;
      notifyListeners();
    }
  }

  /// 대기 중인 사용자 메시지가 있는지 확인
  bool get hasPendingUserMessage => _pendingUserMessage != null;

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
