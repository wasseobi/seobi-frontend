import 'message_role.dart';

/// 메시지 모델 클래스입니다.
class Message {
  final String id;
  final String sessionId;
  final String userId;
  final String content;
  final MessageRole role;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'content': content,
      'role': role.toString().split('.').last,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  Message copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
