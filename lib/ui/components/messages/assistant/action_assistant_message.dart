import 'package:flutter/material.dart';
import '../../../constants/dimensions/message_dimensions.dart';
import 'base_assistant_message.dart';
import 'message_styles.dart';

/// 액션 버튼이 포함된 메시지 컴포넌트
class ActionAssistantMessage extends BaseAssistantMessage {
  final List<Map<String, String>> actions;

  const ActionAssistantMessage({
    super.key,
    required super.message,
    required this.actions,
    super.timestamp,
  });

  @override
  Widget buildMessageContent(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: MessageDecorations.leftBorderDecoration,
      child: Padding(
        padding: const EdgeInsets.only(left: MessageDimensions.padding),
        child: _buildActions(),
      ),
    );
  }

  /// 액션 버튼들을 생성하는 메서드
  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: actions
          .map(
            (action) => Padding(
              padding: const EdgeInsets.only(
                bottom: MessageDimensions.spacing,
                top: MessageDimensions.spacing * 1.5,
              ),
              child: Row(
                children: [
                  Text(
                    action['icon'] ?? '',
                    style: MessageStyles.actionIconStyle,
                  ),
                  const SizedBox(width: MessageDimensions.spacing),
                  Text(
                    action['text'] ?? '',
                    style: MessageStyles.actionTextStyle,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
