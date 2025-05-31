import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/dimensions/message_dimensions.dart';

class UserMessage extends StatelessWidget {
  final String message;
  final bool isSentByUser;

  const UserMessage({
    super.key,
    required this.message,
    required this.isSentByUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: EdgeInsets.all(MessageDimensions.padding),
      decoration: BoxDecoration(
        color: isSentByUser ? AppColors.chatMsgBox : AppColors.white100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isSentByUser ? AppColors.textLight : AppColors.textLight,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
