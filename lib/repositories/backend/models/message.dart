import 'package:flutter/foundation.dart';
import '../../local_database/models/message_role.dart';

// ============================================================================
// Message 모델 정의 (Local Database 호환)
// ============================================================================
// Local Database의 기본 구조를 베이스로 하되, Backend API 확장 기능 포함

/// 채팅 메시지를 나타내는 통합 모델 클래스
///
/// Local Database와 Backend API 모두에서 사용할 수 있도록 설계되었습니다.
/// 기본 필드는 Local Database와 동일하며, 확장 필드는 Backend에서만 사용됩니다.
class Message {
  // ========================================
  // 기본 필드들 (Local Database 호환)
  // ========================================

  /// 메시지의 고유 식별자
  final String id;

  /// 이 메시지가 속한 세션의 ID
  final String sessionId;

  /// 메시지의 실제 텍스트 내용
  final String? content;

  /// 메시지 역할 (Local Database의 MessageRole enum 사용)
  final MessageRole role;

  /// 메시지가 생성된 시각
  final DateTime timestamp;

  // ========================================
  // Backend 확장 필드들
  // ========================================

  /// 메시지를 보낸 사용자의 ID (Backend 전용)
  final String? userId;

  /// 벡터 임베딩 (RAG 시스템용, Backend 전용)
  final List<double>? vector;

  /// 확장 메타데이터 (Backend 전용)
  final Map<String, dynamic>? extensions;

  const Message({
    required this.id,
    required this.sessionId,
    this.content,
    required this.role,
    required this.timestamp,
    // Backend 확장 필드들
    this.userId,
    this.vector,
    this.extensions,
  });

  /// Local Database용 Map 변환 (기본 필드만)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'role': role.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Local Database용 Map에서 생성 (기본 필드만)
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      sessionId: map['session_id'],
      content: map['content'],
      role: MessageRole.values.firstWhere(
        (e) => e.toString() == map['role'],
        orElse: () => MessageRole.user,
      ),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  /// Backend API용 JSON 변환 (모든 필드 포함)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'content': content,
      'role': role.name, // enum의 name 사용
      'timestamp': timestamp.toIso8601String(),
      // Backend 확장 필드들 (값이 있을 때만 포함)
      if (userId != null) 'user_id': userId,
      if (vector != null) 'vector': vector,
      if (extensions != null) 'extensions': extensions,
    };
  }

  /// Backend API용 JSON에서 생성 (모든 필드 포함)
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      content: json['content'] as String?,
      role: _parseRole(json['role']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      // Backend 확장 필드들
      userId: json['user_id'] as String?,
      vector:
          json['vector'] != null
              ? (json['vector'] as List)
                  .map((e) => (e as num).toDouble())
                  .toList()
              : null,
      extensions: json['extensions'] as Map<String, dynamic>?,
    );
  }

  /// 역할 문자열을 MessageRole enum으로 변환하는 헬퍼
  static MessageRole _parseRole(dynamic roleValue) {
    if (roleValue == null) return MessageRole.user;

    final roleString = roleValue.toString();

    // enum name으로 매칭 시도
    for (final role in MessageRole.values) {
      if (role.name == roleString) return role;
    }

    // toString() 형태로 매칭 시도 (Local Database 호환)
    for (final role in MessageRole.values) {
      if (role.toString() == roleString) return role;
    }

    // 기본값
    return MessageRole.user;
  }

  /// Message 인스턴스의 일부 필드를 변경한 새 인스턴스를 생성
  Message copyWith({
    String? id,
    String? sessionId,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    String? userId,
    List<double>? vector,
    Map<String, dynamic>? extensions,
  }) {
    return Message(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      vector: vector ?? this.vector,
      extensions: extensions ?? this.extensions,
    );
  }

  // ========================================
  // 편의 메서드들
  // ========================================

  /// 사용자 메시지인지 확인
  bool get isUserMessage => role == MessageRole.user;

  /// AI 응답인지 확인
  bool get isAssistantMessage => role == MessageRole.assistant;

  /// 시스템 메시지인지 확인
  bool get isSystemMessage => role == MessageRole.system;

  /// 도구 메시지인지 확인
  bool get isToolMessage => role == MessageRole.tool;

  /// 메시지 내용의 간단한 미리보기 (최대 50자)
  String get contentPreview {
    if (content == null || content!.isEmpty) return '(내용 없음)';
    if (content!.length <= 50) return content!;
    return '${content!.substring(0, 47)}...';
  }

  /// 역할을 사용자 친화적 텍스트로 반환
  String get roleDisplayName {
    switch (role) {
      case MessageRole.user:
        return '사용자';
      case MessageRole.assistant:
        return 'AI 어시스턴트';
      case MessageRole.system:
        return '시스템';
      case MessageRole.tool:
        return '도구';
    }
  }

  /// 타임스탬프를 사용자 친화적 형식으로 반환
  String get formattedTimestamp {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    // 1주일 이상이면 실제 날짜 표시
    return '${timestamp.year}년 ${timestamp.month}월 ${timestamp.day}일';
  }

  @override
  String toString() {
    return 'Message(id: $id, sessionId: $sessionId, '
        'content: $contentPreview, role: $role, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          sessionId == other.sessionId &&
          content == other.content &&
          role == other.role &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      id.hashCode ^
      sessionId.hashCode ^
      content.hashCode ^
      role.hashCode ^
      timestamp.hashCode;

  // ========================================
  // 스트리밍 처리 헬퍼 메서드들
  // ========================================

  /// 스트리밍 청크에서 실제 텍스트 콘텐츠를 추출
  static String? getContentFromChunk(Map<String, dynamic> chunk) {
    try {
      if (!chunk.containsKey('type')) {
        debugPrint('[Message] 청크에 type 필드가 없습니다: $chunk');
        return null;
      }

      final type = chunk['type'];
      switch (type) {
        case 'chunk':
          if (chunk.containsKey('content')) {
            final content = chunk['content'].toString();
            debugPrint('[Message] 텍스트 청크: "$content"');
            return content;
          }
          break;
        case 'answer':
          if (chunk.containsKey('answer')) {
            final answer = chunk['answer'] as String;
            debugPrint(
              '[Message] 전체 답변: "${answer.length > 50 ? '${answer.substring(0, 50)}...' : answer}"',
            );
            return answer;
          }
          break;
        case 'tool_calls':
          // tool_calls는 텍스트 콘텐츠가 아니므로 null 반환
          debugPrint('[Message] 도구 호출 신호 감지');
          return null;
        case 'toolmessage':
          // toolmessage는 도구 실행 결과이므로 텍스트 콘텐츠 없음
          debugPrint('[Message] 도구 실행 완료 신호 감지');
          return null;
        case 'start':
          // 스트리밍 시작 신호
          debugPrint('[Message] 스트리밍 시작 신호 감지');
          return null;
        case 'end':
          // 스트리밍 종료 신호
          debugPrint('[Message] 스트리밍 종료 신호 감지');
          return null;
        default:
          if (chunk.containsKey('content')) {
            return chunk['content'] as String?;
          }
      }
      return null;
    } catch (e) {
      debugPrint('[Message] 청크 처리 오류: $e');
      return null;
    }
  }

  /// 스트리밍 청크가 유효한 콘텐츠를 포함하는지 확인
  static bool isValidContentChunk(Map<String, dynamic> chunk) {
    return getContentFromChunk(chunk) != null;
  }

  /// 스트리밍이 완료되었는지 확인
  static bool isStreamingComplete(Map<String, dynamic> chunk) {
    return chunk['type'] == 'end';
  }

  /// 컨텍스트가 성공적으로 저장되었는지 확인
  static bool? getContextSavedStatus(Map<String, dynamic> chunk) {
    if (chunk['type'] == 'end') {
      return chunk['context_saved'] as bool?;
    }
    return null;
  }

  // ========================================
  // 새로운 AI 도구 관련 헬퍼 메서드들
  // ========================================

  /// AI가 도구를 사용하기 시작했는지 확인
  static bool isToolCallStart(Map<String, dynamic> chunk) {
    return chunk['type'] == 'tool_calls';
  }

  /// AI의 도구 실행이 완료되었는지 확인
  static bool isToolCallComplete(Map<String, dynamic> chunk) {
    return chunk['type'] == 'toolmessage';
  }

  /// 도구 호출 정보를 추출 (도구 이름, 매개변수 등)
  static Map<String, dynamic>? getToolCallInfo(Map<String, dynamic> chunk) {
    if (!isToolCallStart(chunk)) return null;

    try {
      final toolCalls = chunk['tool_calls'] as List?;
      if (toolCalls == null || toolCalls.isEmpty) return null;

      final firstCall = toolCalls[0] as Map<String, dynamic>;
      final function = firstCall['function'] as Map<String, dynamic>?;

      return {
        'tool_name': function?['name'] ?? '알 수 없는 도구',
        'tool_id': firstCall['id'],
        'arguments': function?['arguments'],
        'index': firstCall['index'],
      };
    } catch (e) {
      debugPrint('[Message] 도구 호출 정보 추출 오류: $e');
      return null;
    }
  }

  /// 사용자 친화적인 도구 이름 반환
  static String getToolDisplayName(String toolName) {
    switch (toolName.toLowerCase()) {
      case 'search_web':
        return '웹 검색';
      case 'parse_schedule':
        return '일정 파싱';
      case 'create_schedule':
        return '일정 생성';
      case 'generate_insight':
        return '인사이트 생성';
      case 'get_calendar':
        return '캘린더 조회';
      default:
        return toolName;
    }
  }

  /// 스트리밍 청크의 타입을 확인
  static String? getChunkType(Map<String, dynamic> chunk) {
    return chunk['type'] as String?;
  }

  /// 스트리밍 청크가 특정 타입인지 확인
  static bool isChunkType(Map<String, dynamic> chunk, String type) {
    return chunk['type'] == type;
  }

  /// 메타데이터에서 LangGraph 정보 추출
  static Map<String, dynamic>? getLangGraphMetadata(
    Map<String, dynamic> chunk,
  ) {
    final metadata = chunk['metadata'] as Map<String, dynamic>?;
    if (metadata == null) return null;

    return {
      'step': metadata['langgraph_step'],
      'node': metadata['langgraph_node'],
      'path': metadata['langgraph_path'],
      'model_name': metadata['ls_model_name'],
      'provider': metadata['ls_provider'],
    };
  }

  /// 청크가 어떤 AI 모델에서 생성되었는지 확인
  static String? getAIModelName(Map<String, dynamic> chunk) {
    final metadata = getLangGraphMetadata(chunk);
    return metadata?['model_name'] as String?;
  }
}
