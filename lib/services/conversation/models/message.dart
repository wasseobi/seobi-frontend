import 'package:seobi_app/repositories/backend/models/message.dart'
    as backend_message;
import 'package:seobi_app/repositories/local_database/models/message_role.dart';

/// 메시지 데이터 모델
class Message {
  /// 메시지 PK (UUID)
  final String id;

  /// 연관 세션 PK (UUID)
  final String sessionId;

  /// 작성자 PK (UUID)
  final String userId;

  /// 메시지 내용 (SSE 청크들의 리스트)
  final List<String> content;

  /// 역할 (user|assistant|system|tool)
  final MessageRole role;

  /// 작성 시각
  final DateTime timestamp;

  /// 확장 메타데이터 (Backend에서 전달되는 추가 정보)
  final Map<String, dynamic>? extensions;
  const Message({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.extensions,
  });

  /// Backend Message 모델에서 변환
  factory Message.fromBackendMessage(backend_message.Message backendMessage) {
    return Message(
      id: backendMessage.id,
      sessionId: backendMessage.sessionId,
      userId: backendMessage.userId ?? '',
      content: backendMessage.content != null ? [backendMessage.content!] : [],
      role: backendMessage.role, // 동일한 MessageRole enum 사용
      timestamp: backendMessage.timestamp,
      extensions: backendMessage.extensions, // extensions 필드 추가
    );
  }
  Message copyWith({
    String? id,
    String? sessionId,
    String? userId,
    List<String>? content,
    MessageRole? role,
    DateTime? timestamp,
    Map<String, dynamic>? extensions,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      extensions: extensions ?? this.extensions,
    );
  }

  /// 메시지 내용을 모두 연결한 전체 텍스트
  String get fullContent => content.join('');
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          userId == other.userId &&
          content == other.content &&
          role == other.role &&
          timestamp == other.timestamp &&
          extensions == other.extensions;

  @override
  int get hashCode =>
      id.hashCode ^
      sessionId.hashCode ^
      userId.hashCode ^
      content.hashCode ^
      role.hashCode ^
      timestamp.hashCode ^
      extensions.hashCode;

  @override
  String toString() {
    return 'Message{id: $id, sessionId: $sessionId, userId: $userId, content: $content, role: $role, timestamp: $timestamp, extensions: $extensions}';
  }
}
