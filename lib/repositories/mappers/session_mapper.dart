import '../backend/models/session.dart' as backend;
import '../local_db/models/session.dart' as local;

/// Session 모델 간의 변환을 담당하는 매퍼 클래스입니다.
class SessionMapper {
  const SessionMapper._();

  /// 백엔드 Session 모델을 로컬 Session 모델로 변환합니다.
  static local.Session toLocal(backend.Session backendSession) {
    return local.Session(
      id: backendSession.id,
      userId: backendSession.userId,
      startAt: backendSession.startAt,
      finishAt: backendSession.finishAt,
      title: backendSession.title,
      description: backendSession.description,
    );
  }

  /// 로컬 Session 모델을 백엔드 Session 모델로 변환합니다.
  static backend.Session toBackend(local.Session localSession) {
    return backend.Session(
      id: localSession.id,
      userId: localSession.userId,
      startAt: localSession.startAt ?? DateTime.now(), // null인 경우 현재 시간 사용
      finishAt: localSession.finishAt,
      title: localSession.title,
      description: localSession.description,
    );
  }
}
