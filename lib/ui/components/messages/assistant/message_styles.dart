import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'package:seobi_app/ui/constants/app_fonts.dart';

/// 메시지 컴포넌트에서 공통으로 사용하는 스타일 정의
class MessageStyles {
  // 텍스트 스타일
  static final TextStyle messageTextStyle = PretendardStyles.semiBold16
      .copyWith(color: AppColors.gray100);

  static final TextStyle timestampStyle = PretendardStyles.medium10.copyWith(
    color: AppColors.gray80,
  );

  static final TextStyle actionTextStyle = PretendardStyles.regular12.copyWith(
    color: AppColors.gray100,
  );

  static final TextStyle actionIconStyle = PretendardStyles.regular12;

  // 레이아웃 관련 상수
  static const double rightPadding = 50.0;
  static const double maxWidth = 320.0;
  static const double timestampTopPadding = 6.0;
}

/// 메시지에서 공통으로 사용되는 컨테이너 데코레이션
class MessageDecorations {
  static BoxDecoration leftBorderDecoration = BoxDecoration(
    border: Border(left: BorderSide(color: AppColors.gray100, width: 1)),
  );
}
