class Message {
  final String? id;
  final String sessionId;
  final String userId;
  final String content;
  final String role;
  final DateTime? timestamp;

  Message({
    this.id,
    required this.sessionId,
    required this.userId,
    required this.content,
    required this.role,
    this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      sessionId: json['session_id'],
      userId: json['user_id'],
      content: json['content'] ?? '',
      role: json['role'],
      timestamp:
          json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'content': content,
      'role': role,
    };
  }
}
