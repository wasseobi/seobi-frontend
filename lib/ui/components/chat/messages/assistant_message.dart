import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'message_styles.dart';
import '../../common/relative_time.dart';

class AssistantMessage extends StatelessWidget {
  final List<String> content;
  final DateTime? timestamp;

  const AssistantMessage({
    super.key,
    required this.content,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: MessageStyles.messagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarkdownBody(
            data: content.join(),
            styleSheet: MarkdownStyleSheet(
              p: MessageStyles.defaultTextStyle,
              code: MessageStyles.defaultTextStyle.copyWith(
                fontFamily: 'monospace',
                backgroundColor: Colors.grey.withOpacity(0.1),
              ),
              codeblockPadding: const EdgeInsets.all(8),
              blockquote: MessageStyles.defaultTextStyle.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              tableBorder: TableBorder.all(
                color: Colors.grey.withOpacity(0.3),
              ),
              tableHead: TextStyle(fontWeight: FontWeight.bold),
              strong: const TextStyle(fontWeight: FontWeight.bold),
              em: const TextStyle(fontStyle: FontStyle.italic),
            ),
            selectable: true,
            shrinkWrap: true,
          ),
          if (timestamp != null) ...[
            RelativeTime(
              dateTime: timestamp!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}
