import 'package:flutter/material.dart';
import './foldable_message.dart';

class ErrorMessage extends StatelessWidget {
  final List<String> content;

  const ErrorMessage({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return FoldableMessage(
      title: 'Error',
      titleIcon: Icons.error_outline,
      content: content,
      isError: true,
    );
  }
}
