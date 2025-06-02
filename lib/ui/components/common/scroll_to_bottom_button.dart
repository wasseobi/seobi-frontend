import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';

/// 맨 아래로 스크롤하는 버튼 위젯
class ScrollToBottomButton extends StatelessWidget {
  /// 버튼이 보여질지 여부
  final bool visible;

  /// 버튼 클릭 시 호출될 콜백 함수
  final VoidCallback onPressed;

  /// 생성자
  const ScrollToBottomButton({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 버튼이 안 보이는 상태에서는 공간을 차지하지 않기 위해 Visibility 위젯 사용
    return Visibility(
      visible: visible,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: false,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton(
          onPressed: onPressed,
          mini: true,
          tooltip: '맨 아래로 이동',
          backgroundColor: AppColors.white100,
          child: const Icon(
            Icons.arrow_downward,
            color: AppColors.iconLight,
          ),
        ),
      ),
    );
  }
}
