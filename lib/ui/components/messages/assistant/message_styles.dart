import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';

/// 메시지 컴포넌트에서 공통으로 사용하는 스타일 정의
class MessageStyles {
  // 텍스트 스타일
  static const TextStyle messageTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.gray100,
  );
  
  static const TextStyle timestampStyle = TextStyle(
    fontSize: 10,
    color: AppColors.gray80,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle actionTextStyle = TextStyle(
    fontSize: 12,
    color: AppColors.gray100,
  );
  
  static const TextStyle actionIconStyle = TextStyle(
    fontSize: 12,
  );
  
  // 레이아웃 관련 상수
  static const double rightPadding = 50.0;
  static const double maxWidth = 320.0;
  static const double timestampTopPadding = 6.0;
}

/// 메시지에서 공통으로 사용되는 컨테이너 데코레이션
class MessageDecorations {
  static BoxDecoration leftBorderDecoration = BoxDecoration(
    border: Border(
      left: BorderSide(color: AppColors.gray100, width: 1),
    ),
  );
}
