import 'message_role.dart';

class Message {
  final String id;
  final String sessionId;
  final String userId;
  final String? content;
  final MessageRole role;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.content,
    required this.role,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'content': content,
      'role': role.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      sessionId: map['session_id'],
      userId: map['user_id'],
      content: map['content'],
      role: MessageRole.values.firstWhere(
        (e) => e.toString() == map['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.parse(map['timestamp']),
    );
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
