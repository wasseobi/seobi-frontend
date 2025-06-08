/// 메시지 타입 열거형
enum MessageType { user, assistant, tool_call, tool_result, error }

/// 채팅 메시지 모델 클래스
class Message {
  /// 메시지의 고유 식별자
  final String id;

  /// 이 메시지가 속한 세션의 ID
  final String sessionId;

  /// 메시지 타입
  final MessageType type;

  /// 메시지 제목 (선택적)
  /// tool_call의 경우 호출하는 도구의 이름이 들어감
  final String? title;

  /// 메시지 내용 (필수)
  /// - user/assistant: 메시지 본문
  /// - tool_call: 함수 이름/인자 정보가 담긴 json
  /// - tool_result: 도구 실행 결과가 담긴 json
  /// - error: 오류 내용
  final String content;

  /// 메시지 생성 시각
  final DateTime timestamp;

  Message({
    this.id = '',
    this.sessionId = '',
    required this.type,
    this.title,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// JSON에서 Message 객체 생성
  factory Message.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String;
    String content = json['content'] as String;
    final metadata = json['metadata'] as Map<String, dynamic>?;

    MessageType type;
    String? title;

    switch (role) {
      case 'user':
        type = MessageType.user;
        break;
      case 'assistant':
        if (metadata != null && metadata['tool_calls'] != null) {
          type = MessageType.tool_call;
          title = metadata['tool_calls'][0]['function']['name'] as String;
          content =
              metadata['tool_calls'][0]['function']['arguments'] as String;
          break;
        } else {
          type = MessageType.assistant;
        }
      case 'tool':
        if (metadata == null || metadata['result'] == null) {
          type = MessageType.error;
          content = '도구 실행 결과가 없습니다.';
          title = '도구 실행 오류';
        } else {
          type = MessageType.tool_result;
          title = '도구 실행 완료' as String?;
          content = metadata['result']['content'] as String;
          break;
        }
        break;
      default:
        type = MessageType.error;
    }

    return Message(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      type: type,
      title: title,
      content: content,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Message 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'type': type.name,
      if (title != null) 'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Message{id: $id, sessionId: $sessionId, type: $type, title: $title, content: $content, timestamp: $timestamp}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          type == other.type &&
          title == other.title &&
          content == other.content &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      sessionId.hashCode ^
      type.hashCode ^
      (title?.hashCode ?? 0) ^
      content.hashCode ^
      timestamp.hashCode;
}
