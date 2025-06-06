import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'message_styles.dart';

/// 모든 메시지 타입의 기본이 되는 추상 클래스
abstract class BaseAssistantMessage extends StatelessWidget {
  final String message;
  final String? timestamp;

  const BaseAssistantMessage({Key? key, required this.message, this.timestamp})
    : super(key: key);

  @override
  Widget build(BuildContext context) {    return Container(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(),
          const SizedBox(height: 10), // 기본 간격
          buildMessageContent(context), // 하위 클래스에서 구현
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(
                top: MessageStyles.timestampTopPadding,
              ),
              child: Text(timestamp!, style: MessageStyles.timestampStyle),
            ),
        ],
      ),
    );
  }

  /// 메시지 버블 위젯 (모든 메시지 타입에 공통)
  Widget _buildMessageBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: MarkdownBody(
        data: message,
        styleSheet: MarkdownStyleSheet(
          p: MessageStyles.messageTextStyle,
          h1: MessageStyles.messageTextStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          h2: MessageStyles.messageTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          h3: MessageStyles.messageTextStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          strong: MessageStyles.messageTextStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
          em: MessageStyles.messageTextStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
          code: MessageStyles.messageTextStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey.withOpacity(0.2),
          ),
          codeblockPadding: const EdgeInsets.all(8),
          codeblockDecoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          listBullet: MessageStyles.messageTextStyle,
          a: MessageStyles.messageTextStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
        onTapLink: (text, href, title) {
          // 링크 클릭 시 처리 (필요시 구현)
          debugPrint('링크 클릭: $href');
        },
      ),
    );
  }

  /// 메시지 내용을 렌더링하는 메서드 (하위 클래스에서 구현)
  Widget buildMessageContent(BuildContext context);
}
