class Message {
  final String id;
  final String sessionId;
  final String userId;
  final String? content;
  final String role;
  final DateTime timestamp;
  final List<double>? vector;

  Message({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.content,
    required this.role,
    required this.timestamp,
    this.vector,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String?,
      role: json['role'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      vector: json['vector'] != null
          ? (json['vector'] as List).map((e) => e as double).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
      'vector': vector,
    };
  }

  Message copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? content,
    String? role,
    DateTime? timestamp,
    List<double>? vector,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      vector: vector ?? this.vector,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, sessionId: $sessionId, userId: $userId, content: $content, role: $role, timestamp: $timestamp, vector: $vector)';
  }
}