import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/dimensions/message_dimensions.dart';

/// 대기 중인 사용자 메시지를 표시하는 컴포넌트
/// UserMessage와 유사한 디자인을 유지하면서도 로딩 인디케이터를 포함합니다.
/// 이탤릭체로 표시되며 내용에 맞게 크기가 조정되고 오른쪽 정렬됩니다.
/// 로딩 인디케이터는 메시지 카드 왼쪽 외부에 표시됩니다.
class PendingUserMessage extends StatelessWidget {
  final String message;

  const PendingUserMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 로딩 인디케이터 - 카드 왼쪽 외부에 위치
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.main100),
            ),
          ),
          const SizedBox(width: 8),
          // 메시지 카드
          Container(
            padding: EdgeInsets.all(MessageDimensions.padding),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75, // 화면 너비의 75%로 제한
            ),
            decoration: BoxDecoration(
              color: AppColors.chatMsgBox,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic, // 기울임체 유지
              ),
            ),
          ),
        ],
      ),
    );
  }
}
