import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/dimensions/message_dimensions.dart';
import 'card_schedule.dart';

class AssistantMessage extends StatelessWidget {
  final String message;
  final String type; // 'text', 'action', 'card'
  final List<Map<String, String>>? actions;
  final Map<String, String>? card;
  final String? timestamp;

  const AssistantMessage({
    super.key,
    required this.message,
    this.type = 'text',
    this.actions,
    this.card,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 0, right: 50),
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(),
          SizedBox(height: MessageDimensions.spacing * 2.5),
          if ((type == 'card' && card != null) ||
              (actions != null && actions!.isNotEmpty))
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.gray100, width: 1),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(left: MessageDimensions.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (type == 'card' && card != null)
                      ScheduleCard(
                        title: card!['title'] ?? '',
                        time: card!['time'] ?? '',
                        location: card!['location'] ?? '',
                      ), // ✅ 카드 위젯 대체
                    if (actions != null && actions!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: MessageDimensions.spacing * 1.5,
                        ),
                        child: _buildActions(),
                      ),
                  ],
                ),
              ),
            ),
          if (timestamp != null && timestamp!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                timestamp!,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.gray80,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.gray100,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          actions!
              .map(
                (action) => Padding(
                  padding: EdgeInsets.only(bottom: MessageDimensions.spacing),
                  child: Row(
                    children: [
                      Text(
                        action['icon'] ?? '',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: MessageDimensions.spacing),
                      Text(
                        action['text'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray100,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}
