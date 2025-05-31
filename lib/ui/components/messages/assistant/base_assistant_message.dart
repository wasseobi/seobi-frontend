import 'package:flutter/material.dart';
import 'message_styles.dart';

/// 모든 메시지 타입의 기본이 되는 추상 클래스
abstract class BaseAssistantMessage extends StatelessWidget {
  final String message;
  final String? timestamp;

  const BaseAssistantMessage({
    Key? key,
    required this.message,
    this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        left: 0, 
        right: MessageStyles.rightPadding,
      ),
      constraints: const BoxConstraints(maxWidth: MessageStyles.maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(),
          const SizedBox(height: 10), // 기본 간격
          buildMessageContent(context), // 하위 클래스에서 구현
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: MessageStyles.timestampTopPadding),
              child: Text(
                timestamp!,
                style: MessageStyles.timestampStyle,
              ),
            ),
        ],
      ),
    );
  }

  /// 메시지 버블 위젯 (모든 메시지 타입에 공통)
  Widget _buildMessageBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        message,
        style: MessageStyles.messageTextStyle,
      ),
    );
  }

  /// 메시지 내용을 렌더링하는 메서드 (하위 클래스에서 구현)
  Widget buildMessageContent(BuildContext context);
}
