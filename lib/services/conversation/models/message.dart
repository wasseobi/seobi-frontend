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
    // 1. 기본적으로 역할을 assistant로 설정
    MessageRole role = MessageRole.assistant;

    // 2. 역할 설정
    if (backendMessage.role == MessageRole.user) {
      role = MessageRole.user;
    } else if (backendMessage.role == MessageRole.system) {
      role = MessageRole.system;
    } else if (backendMessage.role == MessageRole.tool) {
      // tool 메시지는 assistant로 변환
      role = MessageRole.assistant;
    }

    // 3. 확장 필드 처리
    Map<String, dynamic>? extensions = {};
    
    if (backendMessage.extensions != null) {
      extensions.addAll(backendMessage.extensions!);
      
      // tool_calls 처리
      if (backendMessage.extensions!['tool_calls'] != null) {
        extensions['messageType'] = 'tool_calls';
      } 
      // toolmessage 처리
      else if (backendMessage.extensions!['messageType'] == 'toolmessage') {
        extensions['messageType'] = 'toolmessage';
      }

      // metadata 처리
      if (backendMessage.metadata != null) {
        extensions['metadata'] = backendMessage.metadata;
      }

      // vector 처리 (필요한 경우)
      if (backendMessage.vector != null) {
        extensions['vector'] = backendMessage.vector;
      }
    }

    // 4. 메시지 생성 및 반환
    return Message(
      id: backendMessage.id,
      sessionId: backendMessage.sessionId,
      userId: backendMessage.userId ?? '',
      content: backendMessage.content != null ? [backendMessage.content!] : [],
      role: role,
      timestamp: backendMessage.timestamp,
      extensions: extensions.isEmpty ? null : extensions,
    );
  }

  /// 기존 메시지를 변형하여 새 메시지 생성
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
