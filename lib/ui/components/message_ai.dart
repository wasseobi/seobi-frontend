import 'package:flutter/material.dart';
import '../constants/dimensions/message_dimensions.dart';
import '../constants/app_colors.dart';

class AssistantMessage extends StatelessWidget {
  final String message;

  const AssistantMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.all(MessageDimensions.padding),
        // 배경색 제거
        decoration: BoxDecoration(
          color: Colors.transparent, // 또는 null
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: AppColors.textLight, // 필요에 따라 다르게
            fontSize: MessageDimensions.fontSize,
          ),
        ),
      ),
    );
  }
}
