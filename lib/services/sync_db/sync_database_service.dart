import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../repositories/backend/backend_repository.dart';
import '../../repositories/backend/i_backend_repository.dart';
import '../../repositories/local_database/local_database_repository.dart';
import '../../services/auth/auth_service.dart';
import '../../repositories/backend/models/session.dart' as backend;
import '../../repositories/backend/models/message.dart' as backend;
import '../../repositories/local_database/models/session.dart' as local;
import '../../repositories/local_database/models/message.dart' as local;

/// 로컬 데이터베이스와 백엔드 API를 동기화하는 서비스
/// 
/// 각 get 메소드는 다음 순서로 동작합니다:
/// 1. 로컬 DB와 백엔드 API 요청을 동시에 수행
/// 2. 로컬 DB 결과를 우선 반환 (빠른 응답)
/// 3. 백엔드 응답 확인 후 결과 반환
/// 4. 로컬 DB와 차이가 있으면 갱신 후 새로운 결과 스트림 emit
class SyncDatabaseService {
  static final SyncDatabaseService _instance = SyncDatabaseService._internal();
  factory SyncDatabaseService() => _instance;

  final IBackendRepository _backend = BackendRepository();
  final BackendRepository _backendImpl = BackendRepository();
  final LocalDatabaseRepository _localDb = LocalDatabaseRepository();
  final AuthService _authService = AuthService();

  SyncDatabaseService._internal();

  /// 현재 사용자 정보를 가져오고 인증을 설정합니다.
  Future<String> _getUserIdAndAuthenticate() async {
    final user = await _authService.getUserInfo();
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    if (user.accessToken == null) {
      throw Exception('인증 토큰이 없습니다.');
    }

    _backendImpl.setAuthToken(user.accessToken);
    return user.id;
  }

  /// 사용자 세션 목록을 동기화하여 가져옵니다.
  /// 
  /// 스트림으로 반환되며, 처음에는 로컬 DB 결과, 백엔드 동기화 후 갱신된 결과를 emit합니다.
  Stream<List<local.Session>> getSessionsByUserId(String userId) async* {
    try {
      debugPrint('[SyncDB] 사용자 세션 동기화 시작: $userId');

      // 1. 로컬 DB 결과를 먼저 조회하여 즉시 반환
      final localSessions = await _localDb.getSessions();
      debugPrint('[SyncDB] 로컬 세션 ${localSessions.length}개 조회됨');
      yield localSessions;

      // 2. 인증 설정 후 백엔드 요청
      await _getUserIdAndAuthenticate();
      
      // 3. 백엔드에서 최신 데이터 조회
      final backendSessions = await _backend.getSessionsByUserId(userId);
      debugPrint('[SyncDB] 백엔드 세션 ${backendSessions.length}개 조회됨');

      // 4. 로컬과 백엔드 결과 비교
      final localSessionIds = localSessions.map((s) => s.id).toSet();
      final newSessions = backendSessions
          .where((session) => !localSessionIds.contains(session.id))
          .toList();

      final updatedSessions = <local.Session>[];
      final sessionsToUpdate = <local.Session>[];

      // 기존 세션 업데이트 체크
      for (final backendSession in backendSessions) {
        final localSession = localSessions
            .where((s) => s.id == backendSession.id)
            .firstOrNull;
        
        if (localSession != null) {
          final convertedSession = _convertBackendSessionToLocal(backendSession);
          if (_isSessionDifferent(localSession, convertedSession)) {
            sessionsToUpdate.add(convertedSession);
          }
        }
      }

      // 5. 변경사항이 있으면 로컬 DB 업데이트
      bool hasChanges = false;
      
      if (newSessions.isNotEmpty) {
        debugPrint('[SyncDB] 새로운 세션 ${newSessions.length}개 발견됨');
        final newLocalSessions = newSessions
            .map(_convertBackendSessionToLocal)
            .toList();
        await _localDb.insertSessions(newLocalSessions);
        updatedSessions.addAll(newLocalSessions);
        hasChanges = true;
      }

      if (sessionsToUpdate.isNotEmpty) {
        debugPrint('[SyncDB] 업데이트할 세션 ${sessionsToUpdate.length}개 발견됨');
        // 기존 세션 업데이트 (삭제 후 재삽입)
        for (final session in sessionsToUpdate) {
          await _localDb.deleteSession(session.id);
          await _localDb.insertSession(session);
        }
        hasChanges = true;
      }

      // 6. 변경사항이 있으면 새로운 결과 emit
      if (hasChanges) {
        final finalSessions = await _localDb.getSessions();
        debugPrint('[SyncDB] 동기화 완료 - 최종 세션 ${finalSessions.length}개');
        yield finalSessions;
      }

    } catch (e) {
      debugPrint('[SyncDB] 세션 동기화 오류: $e');
      // 백엔드 오류 시에도 로컬 결과는 유지
      final localSessions = await _localDb.getSessions();
      yield localSessions;
    }
  }

  /// 세션의 메시지 목록을 동기화하여 가져옵니다.
  /// 
  /// 스트림으로 반환되며, 처음에는 로컬 DB 결과, 백엔드 동기화 후 갱신된 결과를 emit합니다.
  Stream<List<local.Message>> getMessagesBySessionId(String sessionId) async* {
    try {
      debugPrint('[SyncDB] 세션 메시지 동기화 시작: $sessionId');

      // 1. 로컬 DB 결과를 먼저 조회하여 즉시 반환
      final localMessages = await _localDb.getSessionMessages(sessionId);
      debugPrint('[SyncDB] 로컬 메시지 ${localMessages.length}개 조회됨');
      yield localMessages;

      // 2. 인증 설정 후 백엔드 요청
      await _getUserIdAndAuthenticate();

      // 3. 백엔드에서 최신 데이터 조회
      final backendMessages = await _backend.getMessagesBySessionId(sessionId);
      debugPrint('[SyncDB] 백엔드 메시지 ${backendMessages.length}개 조회됨');

      // 4. 로컬과 백엔드 결과 비교
      final localMessageIds = localMessages.map((m) => m.id).toSet();
      final newMessages = backendMessages
          .where((message) => !localMessageIds.contains(message.id))
          .toList();

      // 5. 새로운 메시지가 있으면 로컬 DB 업데이트
      if (newMessages.isNotEmpty) {
        debugPrint('[SyncDB] 새로운 메시지 ${newMessages.length}개 발견됨');
        final newLocalMessages = newMessages
            .map(_convertBackendMessageToLocal)
            .toList();
        await _localDb.insertMessages(newLocalMessages);

        // 6. 업데이트된 결과 emit
        final finalMessages = await _localDb.getSessionMessages(sessionId);
        debugPrint('[SyncDB] 메시지 동기화 완료 - 최종 메시지 ${finalMessages.length}개');
        yield finalMessages;
      }

    } catch (e) {
      debugPrint('[SyncDB] 메시지 동기화 오류: $e');
      // 백엔드 오류 시에도 로컬 결과는 유지
      final localMessages = await _localDb.getSessionMessages(sessionId);
      yield localMessages;
    }
  }

  /// 사용자의 모든 메시지를 동기화하여 가져옵니다.
  /// 
  /// 스트림으로 반환되며, 처음에는 로컬 DB 결과, 백엔드 동기화 후 갱신된 결과를 emit합니다.
  Stream<List<local.Message>> getMessagesByUserId(String userId) async* {
    try {
      debugPrint('[SyncDB] 사용자 메시지 동기화 시작: $userId');

      // 1. 로컬 DB에서 사용자의 모든 세션 조회
      final localSessions = await _localDb.getSessions();
      final allLocalMessages = <local.Message>[];
      
      for (final session in localSessions) {
        final sessionMessages = await _localDb.getSessionMessages(session.id);
        allLocalMessages.addAll(sessionMessages);
      }
      
      debugPrint('[SyncDB] 로컬 사용자 메시지 ${allLocalMessages.length}개 조회됨');
      yield allLocalMessages;

      // 2. 인증 설정 후 백엔드 요청
      await _getUserIdAndAuthenticate();

      // 3. 백엔드에서 최신 데이터 조회
      final backendMessages = await _backend.getMessagesByUserId(userId);
      debugPrint('[SyncDB] 백엔드 사용자 메시지 ${backendMessages.length}개 조회됨');

      // 4. 로컬과 백엔드 결과 비교
      final localMessageIds = allLocalMessages.map((m) => m.id).toSet();
      final newMessages = backendMessages
          .where((message) => !localMessageIds.contains(message.id))
          .toList();

      // 5. 새로운 메시지가 있으면 로컬 DB 업데이트
      if (newMessages.isNotEmpty) {
        debugPrint('[SyncDB] 새로운 사용자 메시지 ${newMessages.length}개 발견됨');
        final newLocalMessages = newMessages
            .map(_convertBackendMessageToLocal)
            .toList();
        await _localDb.insertMessages(newLocalMessages);

        // 6. 업데이트된 결과 emit (모든 세션의 메시지 다시 조회)
        final allUpdatedMessages = <local.Message>[];
        final updatedSessions = await _localDb.getSessions();
        
        for (final session in updatedSessions) {
          final sessionMessages = await _localDb.getSessionMessages(session.id);
          allUpdatedMessages.addAll(sessionMessages);
        }
        
        debugPrint('[SyncDB] 사용자 메시지 동기화 완료 - 최종 메시지 ${allUpdatedMessages.length}개');
        yield allUpdatedMessages;
      }

    } catch (e) {
      debugPrint('[SyncDB] 사용자 메시지 동기화 오류: $e');
      // 백엔드 오류 시에도 로컬 결과는 유지
      final localSessions = await _localDb.getSessions();
      final allLocalMessages = <local.Message>[];
      
      for (final session in localSessions) {
        final sessionMessages = await _localDb.getSessionMessages(session.id);
        allLocalMessages.addAll(sessionMessages);
      }
      
      yield allLocalMessages;
    }
  }

  /// 사용자 인사이트를 동기화하여 가져옵니다. (향후 구현)
  /// 
  /// 현재는 백엔드에서만 조회하며, 향후 로컬 캐싱이 추가될 예정입니다.
  Stream<List<Map<String, dynamic>>> getUserInsights(String userId) async* {
    try {
      debugPrint('[SyncDB] 사용자 인사이트 조회 시작: $userId');

      // 인증 설정
      await _getUserIdAndAuthenticate();

      // 백엔드에서 인사이트 조회 (아직 로컬 캐싱 미구현)
      final insights = await _backend.getUserInsights(userId);
      if (insights != null) {
        debugPrint('[SyncDB] 인사이트 ${insights.length}개 조회됨');
        yield insights;
      } else {
        debugPrint('[SyncDB] 인사이트 조회 결과 없음');
        yield <Map<String, dynamic>>[];
      }

    } catch (e) {
      debugPrint('[SyncDB] 인사이트 조회 오류: $e');
      yield <Map<String, dynamic>>[];
    }
  }

  /// 로컬 데이터베이스에 새로운 세션을 추가합니다.
  /// 
  /// 백엔드 동기화 없이 로컬에만 저장됩니다.
  Future<void> addLocalSession(local.Session session) async {
    try {
      debugPrint('[SyncDB] 로컬 세션 추가: ${session.id}');
      await _localDb.insertSession(session);
    } catch (e) {
      debugPrint('[SyncDB] 로컬 세션 추가 오류: $e');
      rethrow;
    }
  }

  /// 로컬 데이터베이스에 새로운 메시지를 추가합니다.
  /// 
  /// 백엔드 동기화 없이 로컬에만 저장됩니다.
  Future<void> addLocalMessage(local.Message message) async {
    try {
      debugPrint('[SyncDB] 로컬 메시지 추가: ${message.id}');
      await _localDb.insertMessage(message);
    } catch (e) {
      debugPrint('[SyncDB] 로컬 메시지 추가 오류: $e');
      rethrow;
    }
  }

  /// 로컬 데이터베이스에 여러 메시지를 한 번에 추가합니다.
  /// 
  /// 백엔드 동기화 없이 로컬에만 저장됩니다.
  Future<void> addLocalMessages(List<local.Message> messages) async {
    try {
      debugPrint('[SyncDB] 로컬 메시지 일괄 추가: ${messages.length}개');
      await _localDb.insertMessages(messages);
    } catch (e) {
      debugPrint('[SyncDB] 로컬 메시지 일괄 추가 오류: $e');
      rethrow;
    }
  }

  // ========================================
  // Private Helper Methods
  // ========================================

  /// 백엔드 세션을 로컬 세션으로 변환
  local.Session _convertBackendSessionToLocal(backend.Session backendSession) {
    return local.Session(
      id: backendSession.id,
      startAt: backendSession.startAt,
      finishAt: backendSession.finishAt,
      title: backendSession.title,
      description: backendSession.description,
    );
  }

  /// 백엔드 메시지를 로컬 메시지로 변환
  local.Message _convertBackendMessageToLocal(backend.Message backendMessage) {
    return local.Message(
      id: backendMessage.id,
      sessionId: backendMessage.sessionId,
      content: backendMessage.content,
      role: backendMessage.role,
      timestamp: backendMessage.timestamp,
    );
  }

  /// 두 세션이 다른지 비교
  bool _isSessionDifferent(local.Session local, local.Session remote) {
    return local.startAt != remote.startAt ||
           local.finishAt != remote.finishAt ||
           local.title != remote.title ||
           local.description != remote.description;
  }
}