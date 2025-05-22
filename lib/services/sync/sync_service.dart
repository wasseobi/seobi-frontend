import 'package:flutter/foundation.dart';
import '../../repositories/backend/backend_repository_interface.dart';
import '../../repositories/backend/backend_repository_factory.dart';
import '../../repositories/local_db/local_db_repository.dart';
import '../../repositories/backend/models/session.dart' as backend;
import '../../repositories/mappers/session_mapper.dart';
import '../../repositories/mappers/message_mapper.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  final BackendRepositoryInterface _backendRepository;
  final LocalDbRepository _localRepository;

  factory SyncService() {
    return _instance;
  }
  SyncService._internal()
    : _backendRepository = BackendRepositoryFactory.instance,
      _localRepository = LocalDbRepository();

  /// 사용자의 세션을 동기화합니다.
  ///
  /// 백엔드에 있는 세션 중 로컬에 없는 세션을 찾아 로컬에 추가하고,
  /// 해당 세션의 메시지들도 함께 동기화합니다.
  ///
  /// [userId]는 동기화를 수행할 사용자의 ID입니다.
  Future<void> syncSessions(String userId) async {
    try {
      final remoteSessions = await _backendRepository.getSessions();
      final localSessions = await _localRepository.getAllSessions();
      final missingSessions = await _findMissingSessions(
        remoteSessions,
        List<backend.Session>.from(localSessions.map(SessionMapper.toBackend)),
      );

      for (final session in missingSessions) {
        final localSession = SessionMapper.toLocal(session);
        await _localRepository.createSession(localSession);

        await _syncSessionMessages(session.id);
      }

      debugPrint('세션 동기화 완료: ${missingSessions.length}개의 세션이 동기화되었습니다.');
    } catch (e) {
      debugPrint('세션 동기화 중 오류 발생: $e');
      rethrow;
    }
  }

  /// 로컬에 없는 세션들을 찾습니다.
  ///
  /// [remoteSessions]은 백엔드의 전체 세션 목록입니다.
  /// [localSessions]은 로컬의 세션 목록을 백엔드 모델로 변환한 것입니다.
  Future<List<backend.Session>> _findMissingSessions(
    List<backend.Session> remoteSessions,
    List<backend.Session> localSessions,
  ) async {
    final localSessionIds = localSessions.map((s) => s.id).toSet();

    return remoteSessions
        .where((session) => !localSessionIds.contains(session.id))
        .toList();
  }

  /// 특정 세션의 메시지들을 동기화합니다.
  ///
  /// [sessionId]는 동기화할 세션의 ID입니다.
  Future<void> _syncSessionMessages(String sessionId) async {
    try {
      final remoteMessages =
          (await _backendRepository.getMessages())
              .where((m) => m.sessionId == sessionId)
              .toList();
      final localMessages = await _localRepository.getMessagesBySessionId(
        sessionId,
      );

      final localMessageIds = localMessages.map((m) => m.id).toSet();
      final missingMessages =
          remoteMessages
              .where((message) => !localMessageIds.contains(message.id))
              .toList();

      for (final message in missingMessages) {
        final localMessage = MessageMapper.toLocal(message);
        await _localRepository.createMessage(localMessage);
      }

      debugPrint(
        '세션($sessionId)의 메시지 동기화 완료: ${missingMessages.length}개의 메시지가 동기화되었습니다.',
      );
    } catch (e) {
      debugPrint('메시지 동기화 중 오류 발생: $e');
      rethrow;
    }
  }
}
