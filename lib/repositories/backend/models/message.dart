/// 메시지 타입 열거형
enum MessageType { user, assistant, toolCall, toolResult, error, summary }

/// 채팅 메시지 모델 클래스
class Message {
  /// 메시지의 고유 식별자
  final String id;

  /// 이 메시지가 속한 세션의 ID
  final String sessionId;

  /// 메시지 타입
  final MessageType type;

  /// 메시지 제목 (선택적)
  /// - tool_call: 호출하는 도구의 이름
  /// - summary: 세션 제목
  final String? title;

  /// 메시지 내용 (필수)
  /// - user/assistant: 메시지 본문
  /// - tool_call: 함수 이름/인자 정보가 담긴 json
  /// - tool_result: 도구 실행 결과가 담긴 json
  /// - error: 오류 내용
  /// - summary: 세션 요약 내용
  final String content;

  /// 메시지 생성 시각
  final DateTime timestamp;

  ///  summary 타입일 때에만 사용되는 세션 종료 시각
  final DateTime? sessionFinishedAt;

  Message({
    this.id = '',
    this.sessionId = '',
    required this.type,
    this.title,
    required this.content,
    DateTime? timestamp,
    this.sessionFinishedAt,
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
          type = MessageType.toolCall;
          final toolCalls = metadata['tool_calls'] as List<dynamic>;
          if (toolCalls.isNotEmpty) {
            final toolCall = toolCalls[0];
            final function = toolCall['function'] as Map<String, dynamic>?;
            if (function != null) {
              title = function['name'] as String;
              // 함수 인자를 JSON 형식으로 포맷팅
              try {
                final arguments = function['arguments'] as String;
                content = '```json\n$arguments\n```';
              } catch (e) {
                content = '';
              }
            }
          }
          break;
        } else {
          type = MessageType.assistant;
        }
        break;
      case 'tool':
        if (metadata == null) {
          type = MessageType.error;
          content = '도구 실행 결과가 없습니다.';
          title = '도구 실행 오류';
        } else if (metadata['tool_call_id'] != null) {
          type = MessageType.toolResult;
          title = metadata['tool_name'] as String? ?? '';

          // 결과 포맷팅 처리
          if (metadata['result'] != null &&
              metadata['result']['content'] != null) {
            final toolResults = metadata['result']['content'];

            // 결과가 JSON 문자열이 아닌 경우 처리
            String formattedResults;
            if (toolResults is String) {
              formattedResults = toolResults;
            } else {
              try {
                formattedResults = toolResults.toString();
              } catch (e) {
                formattedResults = '';
              }
            }

            // 마크다운 형식에 맞게 결과 포맷팅
            if (formattedResults.trim().startsWith('{') ||
                formattedResults.trim().startsWith('[')) {
              content = '```json\n$formattedResults\n```';
            } else {
              content = formattedResults;
            }
          } else {
            // 일반 문자열 처리 (일반적인 도구 결과)
            try {
              if (content.trim().startsWith('{') ||
                  content.trim().startsWith('[')) {
                content = '```json\n$content\n```';
              }
            } catch (e) {
              // 오류 처리 생략 - 기존 콘텐츠 유지
            }
          }
        } else {
          type = MessageType.error;
          title = '알 수 없는 도구 응답';
        }
        break;
      default:
        type = MessageType.error;
        title = '알 수 없는 메시지 유형';
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

  /// 복사본을 생성하며 일부 속성을 변경
  Message copyWith({
    String? id,
    String? sessionId,
    MessageType? type,
    String? Function()? title,
    String? content,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      type: type ?? this.type,
      title: title != null ? title() : this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
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
