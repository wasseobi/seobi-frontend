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

      debugPrint('[HistoryService] 세션 초기화 시작');

      // 현재 사용자 정보 저장
      _currentUserId = _authService.userId;
      
      if (_currentUserId == null) {
        debugPrint('[HistoryService] 로그인되지 않은 상태 - 빈 세션으로 초기화');
        _sessions = [];
        _offset = 0;
        _isInitialized = true;
        notifyListeners();
        return;
      }      // 사용자 인증 및 ID 가져오기
      final userId = await _getUserIdAndAuthenticate();
      
      if (userId == null) {
        debugPrint('[HistoryService] 로그인되지 않은 상태 - 빈 세션으로 초기화');
        _sessions = [];
        _offset = 0;
        _isInitialized = true;
        notifyListeners();
        return;
      }
      
      debugPrint('[HistoryService] 사용자 ID: $userId');

      // Backend에서 해당 사용자의 모든 세션 가져오기
      final backendSessions = await _backendRepository.getSessionsByUserId(userId);

      // Backend Session을 로컬 Session 모델로 변환
      _sessions =
          backendSessions
              .map(
                (backendSession) => Session.fromBackendSession(backendSession),
              )
              .toList();

      // 최신 → 오래된 순서로 정렬 (startAt 기준)
      _sessions.sort((a, b) {
        if (a.startAt == null && b.startAt == null) return 0;
        if (a.startAt == null) return 1;
        if (b.startAt == null) return -1;
        return b.startAt!.compareTo(a.startAt!);
      }); 
        // 오프셋 초기화
      _offset = 0;
      _isInitialized = true;

      debugPrint('[HistoryService] 세션 ${_sessions.length}개 초기화 완료');

      // 초기 세션들 로드 (첫 5개)
      await _loadInitialSessions();

      // UI에 변화 알림
      notifyListeners();
    } catch (e) {
      debugPrint('[HistoryService] 세션 초기화 오류: $e');
      
      // 네트워크 오류인 경우 빈 세션 리스트로 초기화
      if (e.toString().contains('Connection') || 
          e.toString().contains('ClientException') ||
          e.toString().contains('SocketException')) {
        debugPrint('[HistoryService] 네트워크 오류로 인해 오프라인 모드로 초기화');
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
      debugPrint('[HistoryService] 초기 세션 로딩 시작');
      
      if (_sessions.isEmpty) {
        debugPrint('[HistoryService] 로드할 세션이 없음');
        return;
      }
      
      await fetchPaginatedSessions(5);
      debugPrint('[HistoryService] 초기 세션 로딩 완료');
    } catch (e) {
      debugPrint('[HistoryService] 초기 세션 로딩 실패: $e');
      // 초기 세션 로딩 실패는 치명적이지 않음
    }
  }
  /// 특정 세션의 메시지 리스트를 가져와서 채운 세션을 반환
  Future<Session> fetchSession(Session session) async {
    try {
      // 이미 로드된 세션이면 기존 세션 반환
      if (session.isLoaded) {
        debugPrint('[HistoryService] 세션 ${session.id}는 이미 로드됨');
        return session;
      }

      debugPrint('[HistoryService] 세션 ${session.id}의 메시지 로딩 시작');

      // Backend에서 해당 세션의 모든 메시지 가져오기
      final backendMessages = await _backendRepository.getMessagesBySessionId(
        session.id,
      );

      // Backend Message를 로컬 Message 모델로 변환
      final messages =
          backendMessages
              .map(
                (backendMessage) => Message.fromBackendMessage(backendMessage),
              )
              .toList();

      // 최신 → 오래된 순서로 정렬 (timestamp 기준)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // 메시지가 채워지고 로드된 새 세션 객체 생성
      final updatedSession = session.copyWith(
        messages: messages,
        isLoaded: true,
      );

      debugPrint(
        '[HistoryService] 세션 ${session.id}에 메시지 ${messages.length}개 로드 완료',
      );

      return updatedSession;
    } catch (e) {
      debugPrint('[HistoryService] 세션 ${session.id} 메시지 로딩 오류: $e');
      
      // 네트워크 연결 오류인 경우 빈 메시지로 로드된 세션 반환
      if (e.toString().contains('Connection') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('서버 연결') ||
          e.toString().contains('연결이 끊어졌습니다')) {
        debugPrint('[HistoryService] 네트워크 오류로 인해 빈 메시지로 세션 로드: ${session.id}');
        
        // 네트워크 오류 시 빈 메시지 리스트로 로드된 것으로 처리
        return session.copyWith(
          messages: <Message>[],
          isLoaded: true,
        );
      }
      
      rethrow;
    }
  }
  /// n개의 세션을 페이지네이션으로 가져와서 메시지까지 로드
  Future<void> fetchPaginatedSessions(int n) async {
    try {
      debugPrint('[HistoryService] 페이지네이션 시작: offset=$_offset, count=$n');

      // 오프셋부터 n개의 세션 선택
      final endIndex = (_offset + n).clamp(0, _sessions.length);
      final sessionsToLoad = _sessions.sublist(_offset, endIndex);

      // 각 세션의 메시지 로딩하고 업데이트된 세션으로 교체
      int successfullyLoaded = 0;
      for (int i = 0; i < sessionsToLoad.length; i++) {
        final sessionIndex = _offset + i;
        try {
          final updatedSession = await fetchSession(sessionsToLoad[i]);
          _sessions[sessionIndex] = updatedSession;
          successfullyLoaded++;
        } catch (e) {
          debugPrint('[HistoryService] 세션 ${sessionsToLoad[i].id} 로딩 실패, 건너뜀: $e');
          // 개별 세션 로딩 실패 시 빈 메시지로 처리
          _sessions[sessionIndex] = sessionsToLoad[i].copyWith(
            messages: <Message>[],
            isLoaded: true,
          );
          successfullyLoaded++;
        }
      }

      // 오프셋 업데이트
      _offset += sessionsToLoad.length;

      debugPrint('[HistoryService] 페이지네이션 완료: 새 offset=$_offset, 성공: $successfullyLoaded/${sessionsToLoad.length}');

      // UI에 변화 알림
      notifyListeners();
    } catch (e) {
      debugPrint('[HistoryService] 페이지네이션 오류: $e');
      rethrow;
    }
  }

  /// 세션 업데이트 (메시지 추가/수정 시 사용)
  void updateSession(Session updatedSession) {
    final index = _sessions.indexWhere(
      (session) => session.id == updatedSession.id,
    );
    if (index != -1) {
      _sessions[index] = updatedSession;
      debugPrint(
        '[HistoryService] 세션 업데이트: ${updatedSession.id}, 메시지 수: ${updatedSession.messages.length}',
      );

      // UI에 변화 알림
      notifyListeners();
    } else {
      debugPrint('[HistoryService] 세션을 찾을 수 없음: ${updatedSession.id}');
    }
  }

  /// 새 세션 추가
  void addSession(Session newSession) {
    _sessions.insert(0, newSession); // 최신 세션을 맨 앞에 추가
    debugPrint('[HistoryService] 새 세션 추가: ${newSession.id}');

    // UI에 변화 알림
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
    debugPrint('[HistoryService] 대기 중인 사용자 메시지 설정: $message');
    notifyListeners();
  }

  /// 대기 중인 사용자 메시지 조회
  String? get pendingUserMessage => _pendingUserMessage;

  /// 대기 중인 사용자 메시지 클리어
  void clearPendingUserMessage() {
    _pendingUserMessage = null;
    debugPrint('[HistoryService] 대기 중인 사용자 메시지 클리어');
    notifyListeners();
  }
  /// 대기 중인 사용자 메시지가 있는지 확인
  bool get hasPendingUserMessage => _pendingUserMessage != null;

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
