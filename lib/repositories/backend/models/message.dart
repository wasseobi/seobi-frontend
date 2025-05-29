import 'package:flutter/foundation.dart';

/// LangGraph API 응답의 메타데이터 모델
class LangGraphMetadata {
  final int langgraphStep;
  final String langgraphNode;
  final List<String> langgraphTriggers;
  final List<String> langgraphPath;
  final String langgraphCheckpointNs;
  final String checkpointNs;
  final String lsProvider;
  final String lsModelName;
  final String lsModelType;
  final double? lsTemperature;

  LangGraphMetadata({
    required this.langgraphStep,
    required this.langgraphNode,
    required this.langgraphTriggers,
    required this.langgraphPath,
    required this.langgraphCheckpointNs,
    required this.checkpointNs,
    required this.lsProvider,
    required this.lsModelName,
    required this.lsModelType,
    this.lsTemperature,
  });

  factory LangGraphMetadata.fromJson(Map<String, dynamic> json) {
    return LangGraphMetadata(
      langgraphStep: json['langgraph_step'] as int,
      langgraphNode: json['langgraph_node'] as String,
      langgraphTriggers: (json['langgraph_triggers'] as List).cast<String>(),
      langgraphPath: (json['langgraph_path'] as List).cast<String>(),
      langgraphCheckpointNs: json['langgraph_checkpoint_ns'] as String,
      checkpointNs: json['checkpoint_ns'] as String,
      lsProvider: json['ls_provider'] as String,
      lsModelName: json['ls_model_name'] as String,
      lsModelType: json['ls_model_type'] as String,
      lsTemperature: json['ls_temperature'] as double?,
    );
  }

  Map<String, dynamic> toJson() => {
    'langgraph_step': langgraphStep,
    'langgraph_node': langgraphNode,
    'langgraph_triggers': langgraphTriggers,
    'langgraph_path': langgraphPath,
    'langgraph_checkpoint_ns': langgraphCheckpointNs,
    'checkpoint_ns': checkpointNs,
    'ls_provider': lsProvider,
    'ls_model_name': lsModelName,
    'ls_model_type': lsModelType,
    'ls_temperature': lsTemperature,
  };
}

/// LangGraph API의 청크 기본 클래스
class LangGraphChunk {
  final String type;

  LangGraphChunk({required this.type});

  factory LangGraphChunk.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'start':
        return StartChunk.fromJson(json);
      case 'chunk':
        return ContentChunk.fromJson(json);
      case 'end':
        return EndChunk.fromJson(json);
      default:
        throw FormatException('Unknown chunk type: $type');
    }
  }
}

/// 시작 청크 모델
class StartChunk extends LangGraphChunk {
  final Map<String, dynamic> userMessage;

  StartChunk({required this.userMessage}) : super(type: 'start');

  factory StartChunk.fromJson(Map<String, dynamic> json) {
    return StartChunk(
      userMessage: json['user_message'] as Map<String, dynamic>,
    );
  }
}

/// 컨텐츠 청크 모델
class ContentChunk extends LangGraphChunk {
  final String content;
  final LangGraphMetadata metadata;

  ContentChunk({required this.content, required this.metadata})
    : super(type: 'chunk');

  factory ContentChunk.fromJson(Map<String, dynamic> json) {
    return ContentChunk(
      content: json['content'] as String,
      metadata: LangGraphMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>,
      ),
    );
  }
}

/// 종료 청크 모델
class EndChunk extends LangGraphChunk {
  final bool contextSaved;

  EndChunk({required this.contextSaved}) : super(type: 'end');

  factory EndChunk.fromJson(Map<String, dynamic> json) {
    return EndChunk(contextSaved: json['context_saved'] as bool);
  }
}

/// LangGraph API 전체 응답 모델
class LangGraphResponse {
  final String answer;
  final List<LangGraphChunk> chunks;

  LangGraphResponse({required this.answer, required this.chunks});

  factory LangGraphResponse.fromJson(Map<String, dynamic> json) {
    return LangGraphResponse(
      answer: json['answer'] as String,
      chunks:
          (json['chunks'] as List)
              .map(
                (chunk) =>
                    LangGraphChunk.fromJson(chunk as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

class Message {
  static const String ROLE_USER = 'user';
  static const String ROLE_ASSISTANT = 'assistant';
  static const String ROLE_SYSTEM = 'system';

  final String id;
  final String sessionId;
  final String userId;
  final String content;
  final String role;
  final DateTime timestamp;
  final List<double>? vector;

  Message({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.vector,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String? ?? '',
      role: json['role'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      vector:
          json['vector'] != null
              ? (json['vector'] as List).map((e) => e as double).toList()
              : null,
    );
  }

  static Message fromStreamChunk(Map<String, dynamic> chunk) {
    final content = getContentFromChunk(chunk);
    if (content == null) {
      throw FormatException('스트리밍 청크 형식이 잘못되었습니다');
    }

    return Message(
      id: DateTime.now().toIso8601String(),
      sessionId: '', // 세션 ID는 나중에 설정
      userId: 'assistant',
      content: content,
      role: ROLE_ASSISTANT,
      timestamp: DateTime.now(),
    );
  }

  static String? getContentFromChunk(Map<String, dynamic> chunk) {
    try {
      debugPrint('[Message] 청크 처리 시작: ${chunk.toString()}');

      // 전체 응답 처리
      if (chunk.containsKey('answer')) {
        debugPrint('[Message] 전체 응답 발견');
        return chunk['answer'] as String;
      }

      // 개별 청크 처리
      if (!chunk.containsKey('type')) {
        debugPrint('[Message] type 필드 누락');
        return null;
      }

      final type = chunk['type'];

      // 청크 타입별 처리
      switch (type) {
        case 'start':
          debugPrint('[Message] 시작 청크 발견: ${chunk['user_message']}');
          return null;

        case 'chunk':
          if (chunk.containsKey('content')) {
            final content = chunk['content'].toString();

            // 메타데이터 로깅
            if (chunk.containsKey('metadata')) {
              try {
                final metadata = LangGraphMetadata.fromJson(
                  chunk['metadata'] as Map<String, dynamic>,
                );
                debugPrint(
                  '[Message] 메타데이터: \n'
                  '  Step: ${metadata.langgraphStep}\n'
                  '  Node: ${metadata.langgraphNode}\n'
                  '  Model: ${metadata.lsModelName}\n'
                  '  Provider: ${metadata.lsProvider}',
                );
              } catch (e) {
                debugPrint('[Message] 메타데이터 파싱 실패: $e');
              }
            }

            debugPrint('[Message] 컨텐츠 청크 처리: "$content"');
            return content;
          }
          return null;

        case 'end':
          debugPrint(
            '[Message] 종료 청크 발견: context_saved=${chunk['context_saved']}',
          );
          return null;

        default:
          debugPrint('[Message] 지원하지 않는 청크 타입: $type');
          return null;
      }
    } catch (e, stackTrace) {
      debugPrint('[Message] 청크 처리 오류: $e\n$stackTrace');
      return null;
    }
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
