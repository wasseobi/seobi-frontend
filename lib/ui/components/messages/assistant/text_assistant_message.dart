import 'package:flutter/material.dart';
import 'base_assistant_message.dart';

/// 텍스트만 표시하는 기본 메시지
class TextAssistantMessage extends BaseAssistantMessage {
  const TextAssistantMessage({
    super.key,
    required super.message,
    super.timestamp,
  });

  @override
  Widget buildMessageContent(BuildContext context) {
    // 텍스트 메시지는 추가 콘텐츠가 없으므로 빈 컨테이너 반환
    return const SizedBox.shrink();
  }
}
