import 'models/message.dart';
import 'models/session.dart';

/// 로컬 데이터베이스 접근을 위한 인터페이스입니다.
abstract class LocalDbRepositoryInterface {
  /// 데이터베이스 연결을 초기화합니다.
  Future<void> init();

  // Session 관련 메서드
  Future<List<Session>> getAllSessions();
  Future<Session?> getSessionById(String id);
  Future<Session> createSession(Session session);
  Future<void> updateSession(Session session);
  Future<void> deleteSession(String id);

  // Message 관련 메서드
  Future<List<Message>> getAllMessages();
  Future<List<Message>> getMessagesBySessionId(String sessionId);
  Future<Message?> getMessageById(String id);
  Future<Message> createMessage(Message message);
  Future<void> updateMessage(Message message);
  Future<void> deleteMessage(String id);

  /// 데이터베이스 연결을 닫습니다.
  Future<void> close();
}
