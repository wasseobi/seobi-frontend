import 'package:flutter/material.dart';
import './foldable_message.dart';

class ToolResultMessage extends StatelessWidget {
  final List<String> content;

  const ToolResultMessage({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return FoldableMessage(
      title: '도구 실행 결과',
      titleIcon: Icons.description_outlined,
      content: content,
    );
  }
}
