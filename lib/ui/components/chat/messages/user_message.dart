import 'package:flutter/material.dart';
import 'message_styles.dart';

class UserMessage extends StatelessWidget {
  final List<String> content;

  const UserMessage({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: MessageStyles.maxWidth),
        margin: MessageStyles.messageMargin,
        padding: MessageStyles.messagePadding,
        decoration: MessageDecorations.userDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: content.map((text) => 
            Text(text, style: MessageStyles.defaultTextStyle)
          ).toList(),
        ),
      ),
    );
  }
}
