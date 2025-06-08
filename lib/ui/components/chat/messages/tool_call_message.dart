import 'package:flutter/material.dart';
import './foldable_message.dart';

class ToolCallMessage extends StatelessWidget {
  final String title;
  final List<String> content;

  const ToolCallMessage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return FoldableMessage(
      title: '$title 도구 호출',
      titleIcon: Icons.build_outlined,
      content: content,
    );
  }
}
