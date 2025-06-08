import 'package:flutter/material.dart';
import '../../../constants/dimensions/message_dimensions.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'base_assistant_message.dart';
import 'message_styles.dart';

/// 도구 호출을 표시하는 메시지 컴포넌트
class ToolCallsAssistantMessage extends BaseAssistantMessage {
  final Map<String, dynamic> toolCalls;

  const ToolCallsAssistantMessage({
    super.key,
    required super.message,
    required this.toolCalls,
    super.timestamp,
  });

  @override
  Widget buildMessageContent(BuildContext context) {
    // tool_calls에서 함수 이름 추출
    final functionName = toolCalls['function']?['name'] as String? ?? '알 수 없는 도구';
    final arguments = toolCalls['function']?['arguments'] ?? '{}';

    return Container(
      decoration: MessageDecorations.leftBorderDecoration,
      child: Padding(
        padding: const EdgeInsets.only(left: MessageDimensions.padding),
        child: InkWell(
          onTap: () {
            // 툴팁 표시
            final overlay = OverlayEntry(
              builder: (context) => Positioned(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '인자: $arguments',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
              ),
            );

            // 3초 후 툴팁 자동 제거
            Overlay.of(context).insert(overlay);
            Future.delayed(const Duration(seconds: 3), () {
              overlay.remove();
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: MessageDimensions.spacing * 1.5,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.build_outlined,
                  size: MessageDimensions.iconSize,
                  color: AppColors.gray60,
                ),
                const SizedBox(width: MessageDimensions.spacing),
                Text(
                  '$functionName 도구 사용 중...',
                  style: MessageStyles.actionTextStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
