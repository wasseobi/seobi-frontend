import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:seobi_app/repositories/gps/gps_repository.dart';
import 'package:seobi_app/services/auth/auth_service.dart';
import 'package:seobi_app/services/conversation/history_service.dart';
import 'package:seobi_app/repositories/backend/backend_repository.dart';
import 'package:seobi_app/services/conversation/sse_handler.dart';
import 'package:seobi_app/services/tts/tts_service.dart';
import 'models/session.dart' as local_session;

/// 대화 서비스 v2 - Auth와 History 서비스를 통합 관리
class ConversationService2 {
  static final ConversationService2 _instance =
      ConversationService2._internal();
  factory ConversationService2() => _instance;
  
  final AuthService _authService = AuthService();
  final HistoryService _historyService = HistoryService();
  final TtsService _ttsService = TtsService();

  final BackendRepository _backendRepository = BackendRepository();
  final GpsRepository _gpsRepository = GpsRepository();

  // 세션 자동 종료를 위한 타이머
  Timer? _sessionTimer;
  // 세션 자동 종료 시간 (3분)
  static const Duration _sessionTimeout = Duration(minutes: 3);
  ConversationService2._internal();

  /// 초기화
  Future<void> initialize() async {
    // AuthService 초기화
    await _authService.init();

    // HistoryService 초기화
    await _historyService.initialize();

    // TtsService 초기화
    await _ttsService.initialize();

    

    debugPrint('[ConversationService2] 서비스 초기화 완료');
  }

  /// 현재 사용자 정보를 가져오고 인증 설정
  Future<String> _getUserIdAndAuthenticate() async {
    final user = await _authService.getUserInfo();
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    if (user.accessToken == null) {
      throw Exception('인증 토큰이 없습니다.');
    }

    _backendRepository.setAuthToken(user.accessToken);
    return user.id;
  }

  /// 가장 최근 세션을 가져오거나 새로 생성
  Future<local_session.Session> _getOrCreateLatestSession() async {
    final userId = await _getUserIdAndAuthenticate();

    // History Service에서 세션 목록 가져오기
    final sessions = _historyService.sessions;

    // 활성 세션이 있는지 확인
    final activeSession =
        sessions.isNotEmpty
            ? sessions.firstWhere(
              (session) => session.isActive,
              orElse: () => sessions.first,
            )
            : null; // 활성 세션이 있고 열려있다면 반환
    if (activeSession != null && activeSession.isActive) {
      debugPrint('[ConversationService2] 기존 활성 세션 사용: ${activeSession.id}');

      // 세션이 로드되지 않았다면 로드된 상태로 변경
      if (!activeSession.isLoaded) {
        final loadedSession = activeSession.copyWith(isLoaded: true);
        _historyService.updateSession(loadedSession);
        return loadedSession;
      }

      return activeSession;
    } // 새 세션 생성
    debugPrint('[ConversationService2] 새 세션 생성 중...');
    final backendSession = await _backendRepository.postSession(userId);
    final newSession = local_session.Session.fromBackendSession(
      backendSession,
    ).copyWith(
      isLoaded: true, // 새로 생성된 세션은 로드된 상태로 설정
    );

    // History Service에 새 세션 추가
    _historyService.addSession(newSession);

    debugPrint('[ConversationService2] 새 세션 생성 완료: ${newSession.id}');
    return newSession;
  }

  /// 메시지 전송 및 세션 업데이트
  Future<void> sendMessage(String content) async {
    try {
      debugPrint('[ConversationService2] 메시지 전송 시작');

      // 세션 가져오기 또는 생성
      final session = await _getOrCreateLatestSession();

      // 사용자 ID 가져오기 및 인증
      final userId = await _getUserIdAndAuthenticate();
      // 타이머 리셋
      _resetSessionTimer(session.id);

      // SSE 이벤트 핸들러 등록 (TTS 서비스 연결)
      final sseHandler = SseHandler(_historyService);

      _historyService.setPendingUserMessage(content);

      debugPrint('[ConversationService2] 메시지 전송 요청: ${session.id}');

      // 메시지 전송 및 SSE 스트림 받기
      final stream = _backendRepository.postSendMessage(
        sessionId: session.id,
        userId: userId,
        content: content,
        location: (await _gpsRepository.getCurrentPosition()).toJson(),
      ); // 스트림 리스닝 시작

      await for (final data in stream) {
        try {
          if (data is Map<String, dynamic>) {
            // Map 형식 데이터 처리
            sseHandler.handleEvent(data, session.id, userId);
          } else if (data is List) {
            // List 형식 데이터 처리: 각 아이템을 개별적으로 처리
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                sseHandler.handleEvent(item, session.id, userId);
              } else {
                debugPrint(
                  '[ConversationService2] 지원하지 않는 리스트 아이템 형식: ${item.runtimeType}',
                );
              }
            }
          } else {
            // 기타 형식 데이터 로깅
            debugPrint(
              '[ConversationService2] 지원하지 않는 데이터 형식: ${data.runtimeType}',
            );
          }
        } catch (e) {
          debugPrint('[ConversationService2] 이벤트 처리 중 오류: $e');
        }
      }

      debugPrint('[ConversationService2] 메시지 전송 완료');
    } catch (e) {
      debugPrint('[ConversationService2] ❌ 메시지 전송 실패: $e');
      rethrow;
    }
  }

  /// 타이머 시작 또는 재설정
  void _resetSessionTimer(String sessionId) {
    debugPrint('[ConversationService2] ⏰ 세션 자동 종료 타이머 초기화: $sessionId');
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, () => _autoFinishSession(sessionId));
  }

  /// 세션 종료
  Future<void> finishSession(String sessionId) async {
    final session = _historyService.getSessionById(sessionId);
    if (session == null || !session.isActive) {
      debugPrint('[ConversationService2] ⚠️ 종료할 활성 세션을 찾을 수 없음: $sessionId');
      return;
    }

    try {
      // 백엔드에서 세션 종료
      final closedSession = await _backendRepository.postSessionFinish(
        sessionId,
      );
      debugPrint('[ConversationService2] ✅ 세션 종료 완료: $sessionId');

      // 로컬에서도 세션 상태 업데이트
      final finishedSession = session.copyWith(
        finishAt: closedSession.finishAt,
        title: closedSession.title,
        description: closedSession.description,
      );
      debugPrint(
        '[ConversationService2] 세션 요약: ${finishedSession.title}, '
        '설명: ${finishedSession.description}, '
        '시작: ${finishedSession.startAt}, '
        '종료: ${finishedSession.finishAt}',
      );
      _historyService.updateSession(finishedSession);
    } catch (e) {
      debugPrint('[ConversationService2] ⚠️ 세션 종료 실패: $e');
    }
  }

  /// 세션 자동 종료
  Future<void> _autoFinishSession(String sessionId) async {
    debugPrint('[ConversationService2] ⏰ 세션 자동 종료 시작: $sessionId');
    await finishSession(sessionId);
  }

  /// 리소스 정리
  Future<void> dispose() async {
    debugPrint('[ConversationService2] 🧹 리소스 정리 시작');

    try {
      // 0. 타이머 정리
      _sessionTimer?.cancel();
      _sessionTimer = null;

      // 1. 활성 세션이 있다면 종료
      final activeSession =
          _historyService.sessions.isNotEmpty
              ? _historyService.sessions.firstWhere(
                (session) => session.isActive,
                orElse: () => _historyService.sessions.first,
              )
              : null;
      if (activeSession != null && activeSession.isActive) {
        await finishSession(activeSession.id);
      }

      // 2. 대기 중인 사용자 메시지 정리
      if (_historyService.hasPendingUserMessage) {
        _historyService.clearPendingUserMessage();
        debugPrint('[ConversationService2] ✅ 대기 중인 메시지 정리 완료');
      }

      // 3. 히스토리 서비스 정리
      (_historyService as ChangeNotifier).dispose();
      debugPrint('[ConversationService2] ✅ 히스토리 서비스 정리 완료');

      // 4. TTS 서비스 정리
      await _ttsService.dispose();
      debugPrint('[ConversationService2] ✅ TTS 서비스 정리 완료');
    } catch (e) {
      debugPrint('[ConversationService2] ❌ 리소스 정리 중 오류 발생: $e');
      rethrow;
    }

    debugPrint('[ConversationService2] ✅ 모든 리소스 정리 완료');
  }
}
