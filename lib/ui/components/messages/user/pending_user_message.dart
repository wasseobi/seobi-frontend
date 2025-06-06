import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/dimensions/message_dimensions.dart';

/// 대기 중인 사용자 메시지를 표시하는 컴포넌트
/// 기존 UserMessage와 유사하지만 기울임꼴로 표시되어 임시 상태임을 나타냅니다.
class PendingUserMessage extends StatelessWidget {
  final String message;

  const PendingUserMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(MessageDimensions.padding),
      decoration: BoxDecoration(
        color: AppColors.chatMsgBox.withOpacity(0.7), // 약간 투명하게 표시
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.main100.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 로딩 인디케이터
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.main100),
            ),
          ),
          const SizedBox(width: 8),
          // 메시지 텍스트
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic, // 기울임꼴
              ),
            ),
          ),
        ],
      ),
    );
  }
}
