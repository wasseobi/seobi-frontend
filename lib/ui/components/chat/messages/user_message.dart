import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import 'message_styles.dart';

class UserMessage extends StatelessWidget {
  final List<String> content;
  final bool isPending;

  const UserMessage({super.key, this.isPending = false, required this.content});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 로딩 인디케이터 (isPending일 때만 표시)
          if (isPending)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: AppDimensions.progressIndicatorMedium,
                height: AppDimensions.progressIndicatorMedium,
                child: CircularProgressIndicator(color: AppColors.main100),
              ),
            ),
          // 메시지 컨테이너
          Container(
            constraints: const BoxConstraints(maxWidth: MessageStyles.maxWidth),
            margin: MessageStyles.messageMargin,
            padding: MessageStyles.messagePadding,
            decoration: MessageDecorations.userDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children:
                  content
                      .map(
                        (text) =>
                            Text(text, style: MessageStyles.defaultTextStyle),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
