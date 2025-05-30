import 'package:flutter/material.dart';
import '../constants/dimensions/message_dimensions.dart';
import '../constants/dimensions/app_dimensions.dart';

class MessageUser extends StatelessWidget {
  final String content;

  const MessageUser({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: AppDimensions.spacing8,
        horizontal: AppDimensions.spacing16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75, // 최대 75%
              ),
              padding: EdgeInsets.all(MessageDimensions.padding),
              decoration: BoxDecoration(
                color: const Color(0xFF6200EA),
                borderRadius: BorderRadius.circular(AppDimensions.radius12),
              ),
              child: Text(
                content,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
