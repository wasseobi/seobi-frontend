import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import './foldable_message.dart';
import 'message_styles.dart';

class ToolResultMessage extends StatelessWidget {
  final List<String> content;
  final String title;

  const ToolResultMessage({
    super.key,
    this.title = '도구 실행 결과',
    required this.content,
  });

  @override  Widget build(BuildContext context) {
    return FoldableMessage(
      title: title,
      titleIcon: Icons.description_outlined,
      content: content,
      customContentBuilder: (contentList) => MarkdownBody(
        data: contentList.join(),
        styleSheet: MarkdownStyleSheet(
          p: MessageStyles.defaultTextStyle,
          code: MessageStyles.defaultTextStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.grey.withOpacity(0.1),
            fontSize: MessageStyles.defaultTextStyle.fontSize,
          ),
          codeblockPadding: const EdgeInsets.all(8),
          codeblockDecoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          blockquote: MessageStyles.defaultTextStyle.copyWith(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          blockquotePadding: const EdgeInsets.symmetric(horizontal: 8),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.grey.withOpacity(0.5),
                width: 4,
              ),
            ),
          ),
          tableBorder: TableBorder.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1,
            style: BorderStyle.solid,
          ),
          tableColumnWidth: const FlexColumnWidth(),
          tableHead: MessageStyles.defaultTextStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          tableBody: MessageStyles.defaultTextStyle,
          tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          strong: MessageStyles.defaultTextStyle.copyWith(fontWeight: FontWeight.bold),
          em: MessageStyles.defaultTextStyle.copyWith(fontStyle: FontStyle.italic),
          h1: MessageStyles.defaultTextStyle.copyWith(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          h2: MessageStyles.defaultTextStyle.copyWith(
            fontSize: 18, 
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          h3: MessageStyles.defaultTextStyle.copyWith(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
        ),
        selectable: true,
      ),
    );
  }
}
