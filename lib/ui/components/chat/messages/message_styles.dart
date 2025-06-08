import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';

class MessageStyles {
  // 텍스트 스타일
  static const TextStyle defaultTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.gray100,
  );

  static const TextStyle monospaceTextStyle = TextStyle(
    fontSize: 14,
    fontFamily: 'monospace',
    color: AppColors.gray100,
  );

  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.gray80,
  );

  // 레이아웃 관련 상수
  static const EdgeInsets messagePadding = EdgeInsets.all(12);
  static const EdgeInsets messageMargin = EdgeInsets.symmetric(vertical: 4, horizontal: 8);
  static const double borderRadius = 12.0;
  static const double maxWidth = 320.0;  // 메시지 배경색
  static final Color userMessageColor = AppColors.chatMsgBox;
    // 메시지 테두리 관련
  static const Color leftBorderColor = AppColors.gray100;
  static const double borderWidth = 1.0;
  
  // 애니메이션 지속 시간
  static const Duration expandDuration = Duration(milliseconds: 200);
}

class MessageDecorations {
  static BoxDecoration userDecoration = BoxDecoration(
    color: MessageStyles.userMessageColor,
    borderRadius: BorderRadius.circular(MessageStyles.borderRadius),
  );

  static BoxDecoration leftBorderDecoration = BoxDecoration(
    border: Border(
      left: BorderSide(
        color: MessageStyles.leftBorderColor,
        width: 1,
      ),
    ),
  );
}
