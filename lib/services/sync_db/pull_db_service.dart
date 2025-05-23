import 'package:flutter/foundation.dart';
import 'package:seobi_app/repositories/backend/backend_repository_factory.dart';
import 'package:seobi_app/repositories/backend/i_backend_repository.dart';
import 'package:seobi_app/repositories/backend/models/message.dart' as backend;
import 'package:seobi_app/repositories/backend/models/session.dart' as backend;
import 'package:seobi_app/repositories/local_database/local_database_repository.dart';
import 'package:seobi_app/repositories/local_database/models/message.dart';
import 'package:seobi_app/repositories/local_database/models/session.dart';
import 'package:seobi_app/repositories/local_database/models/message_role.dart';

class PullDbService {
  static final PullDbService _instance = PullDbService._internal();
  factory PullDbService() => _instance;

  final IBackendRepository _backendRepository = BackendRepositoryFactory.instance;
  final LocalDatabaseRepository _localRepository = LocalDatabaseRepository();

  PullDbService._internal();

  /// 백엔드의 세션과 메시지를 로컬 DB에 동기화합니다.
  Future<void> synchronize() async {
    try {      debugPrint('[PullDbService] 백엔드 데이터 동기화 시작');
      
      // 1. 원격에서 세션 목록을 가져옴
      final remoteSessions = await _backendRepository.getSessions();
      debugPrint('[PullDbService] 원격 세션 ${remoteSessions.length}개 조회됨');

      // 2. 로컬의 세션 목록을 가져옴
      final localSessions = await _localRepository.getSessions();
      final localSessionIds = localSessions.map((s) => s.id).toSet();

      // 3. 로컬에 없는 세션들을 필터링
      final newSessions = remoteSessions.where(
        (session) => !localSessionIds.contains(session.id)
      ).toList();
      
      if (newSessions.isEmpty) {
        debugPrint('[PullDbService] 동기화할 새로운 세션이 없습니다.');
        return;
      }

      debugPrint('[PullDbService] 새로운 세션 ${newSessions.length}개 발견됨');

      // 4. 새로운 세션을 로컬 DB에 저장
      await _localRepository.insertSessions(newSessions.map((session) => 
        session.toLocalSession()).toList());
      
      // 5. 새로운 세션들의 메시지를 가져와서 저장
      for (final session in newSessions) {
        final messages = await _backendRepository.getMessagesBySessionId(session.id);
        await _localRepository.insertMessages(
          messages.map((message) => message.toLocalMessage()).toList()
        );        debugPrint('[PullDbService] 세션 ${session.id}의 메시지 ${messages.length}개 저장됨');
      }

      debugPrint('[PullDbService] 백엔드 데이터 동기화 완료');
    } catch (e) {
      debugPrint('[PullDbService] 백엔드 데이터 동기화 중 오류 발생: $e');
      rethrow;
    }
  }
}

/// 백엔드 세션 모델을 로컬 세션 모델로 변환하는 확장 메서드
extension SessionConverter on backend.Session {
  Session toLocalSession() => Session(
    id: id,
    startAt: startAt,
    finishAt: finishAt,
    title: title,
    description: description,
  );
}

/// 백엔드 메시지 모델을 로컬 메시지 모델로 변환하는 확장 메서드
extension MessageConverter on backend.Message {
  Message toLocalMessage() => Message(
    id: id,
    sessionId: sessionId,
    content: content,
    role: _convertMessageRole(role),
    timestamp: timestamp,
  );

  MessageRole _convertMessageRole(String role) {
    switch (role.toLowerCase()) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }
}