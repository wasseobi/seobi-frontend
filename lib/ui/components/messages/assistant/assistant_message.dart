import 'package:flutter/material.dart';
import 'action_assistant_message.dart';
import 'card_assistant_message.dart';
import 'message_types.dart';
import 'text_assistant_message.dart';
import 'tool_calls_assistant_message.dart';
import 'tool_result_assistant_message.dart';

/// 메시지 생성을 위한 팩토리 클래스
/// 모든 메시지 타입은 enum으로 관리됩니다
class AssistantMessage extends StatelessWidget {
  final String message;
  final MessageType type;
  final List<Map<String, String>>? actions;
  final Map<String, String>? card;
  final Map<String, dynamic>? toolCalls;
  final Map<String, dynamic>? metadata;
  final String? timestamp;

  const AssistantMessage({
    super.key,
    required this.message,
    this.type = MessageType.text,
    this.actions,
    this.card,
    this.toolCalls,
    this.metadata,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    // 타입에 따라 적절한 메시지 위젯 생성
    switch (type) {
      case MessageType.action:
        if (actions != null) {
          return ActionAssistantMessage(
            message: message,
            actions: actions!,
            timestamp: timestamp,
          );
        }
        return TextAssistantMessage(message: message, timestamp: timestamp);

      case MessageType.card:
        if (card != null) {
          return CardAssistantMessage(
            message: message,
            card: card!,
            actions: actions,
            timestamp: timestamp,
          );
        }
        return TextAssistantMessage(message: message, timestamp: timestamp);

      case MessageType.tool_calls:
        if (toolCalls != null) {
          return ToolCallsAssistantMessage(
            message: message,
            toolCalls: toolCalls!,
            timestamp: timestamp,
          );
        }
        return TextAssistantMessage(message: message, timestamp: timestamp);

      case MessageType.toolmessage:
        if (metadata != null) {
          return ToolResultAssistantMessage(
            message: message,
            metadata: metadata!,
            timestamp: timestamp,
          );
        }
        return TextAssistantMessage(message: message, timestamp: timestamp);

      case MessageType.text:
        return TextAssistantMessage(message: message, timestamp: timestamp);
    }
  }
}
