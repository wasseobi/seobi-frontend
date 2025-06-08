import 'package:flutter/material.dart';
import '../../../constants/dimensions/message_dimensions.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'base_assistant_message.dart';
import 'message_styles.dart';
import 'dart:convert';

/// 도구 실행 결과를 표시하는 메시지 컴포넌트
class ToolResultAssistantMessage extends BaseAssistantMessage {
  final Map<String, dynamic> metadata;

  const ToolResultAssistantMessage({
    super.key,
    required super.message,
    required this.metadata,
    super.timestamp,
  });

  @override
  Widget buildMessageContent(BuildContext context) {
    return Container(
      decoration: MessageDecorations.leftBorderDecoration,
      child: Padding(
        padding: const EdgeInsets.only(left: MessageDimensions.padding),
        child: InkWell(
          onTap: () {
            // 결과 표시 다이얼로그
            showDialog(
              context: context,
              builder: (context) => Dialog(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.6,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '도구 실행 결과',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            const JsonEncoder.withIndent('  ')
                                .convert(metadata),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              barrierDismissible: true, // 외부 영역 터치 시 닫힘
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: MessageDimensions.spacing * 1.5,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: MessageDimensions.iconSize,
                  color: AppColors.gray60,
                ),
                const SizedBox(width: MessageDimensions.spacing),
                const Text(
                  '정보를 수집하는 중...',
                  style: MessageStyles.actionTextStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
