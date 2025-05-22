import '../backend/models/message.dart' as backend;
import '../local_db/models/message.dart' as local;
import '../local_db/models/message_role.dart';

/// Message 모델 간의 변환을 담당하는 매퍼 클래스입니다.
class MessageMapper {
  const MessageMapper._();

  /// 백엔드 Message 모델을 로컬 Message 모델로 변환합니다.
  static local.Message toLocal(backend.Message backendMessage) {
    return local.Message(
      id: backendMessage.id,
      sessionId: backendMessage.sessionId,
      userId: backendMessage.userId,
      content: backendMessage.content ?? '',
      role: MessageRole.values.firstWhere(
        (e) => e.name == backendMessage.role,
        orElse: () => MessageRole.user,
      ),
      timestamp: backendMessage.timestamp,
    );
  }

  /// 로컬 Message 모델을 백엔드 Message 모델로 변환합니다.
  static backend.Message toBackend(local.Message localMessage) {
    return backend.Message(
      id: localMessage.id,
      sessionId: localMessage.sessionId,
      userId: localMessage.userId,
      content: localMessage.content,
      role: localMessage.role.name,
      timestamp: localMessage.timestamp,
    );
  }
}
