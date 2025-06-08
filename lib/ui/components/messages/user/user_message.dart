import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/dimensions/message_dimensions.dart';

class UserMessage extends StatelessWidget {
  final String message;
  final bool isSentByUser;
  final bool isPending;

  const UserMessage({
    super.key,
    required this.message,
    required this.isSentByUser,
    this.isPending = false,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isPending) ...[
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.main100),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          padding: EdgeInsets.all(MessageDimensions.padding),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
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
              fontStyle: isPending ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
