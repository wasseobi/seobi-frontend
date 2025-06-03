import 'package:flutter/material.dart';
import '../../../constants/dimensions/message_dimensions.dart';
import '../../common/schedule_card.dart';
import '../../box/schedules/schedule_card_model.dart';
import '../../box/schedules/schedule_types.dart';
import 'base_assistant_message.dart';
import 'message_styles.dart';

/// 카드가 포함된 메시지 컴포넌트
class CardAssistantMessage extends BaseAssistantMessage {
  final Map<String, String> card;
  final List<Map<String, String>>? actions;

  const CardAssistantMessage({
    super.key,
    required super.message,
    required this.card,
    this.actions,
    super.timestamp,
  });

  @override
  Widget buildMessageContent(BuildContext context) {
    // Create ScheduleCardModel from card data
    final scheduleModel = ScheduleCardModel(
      id: int.parse(card['id'] ?? '0'),
      title: card['title'] ?? '',
      time: card['time'] ?? '',
      location: card['location'] ?? '',
      type: ScheduleType.message,
      registeredTime: card['registeredTime'] ?? DateTime.now().toString(),
    );

    return Container(
      decoration: MessageDecorations.leftBorderDecoration,
      child: Padding(
        padding: const EdgeInsets.only(left: MessageDimensions.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScheduleCard(
              schedule: scheduleModel,
              onTap: () {
                // Handle card tap if needed
              },
            ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                  top: MessageDimensions.spacing * 1.5,
                ),
                child: _buildActions(),
              ),
          ],
        ),
      ),
    );
  }

  /// 액션 버튼들을 생성하는 메서드
  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          actions!
              .map(
                (action) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: MessageDimensions.spacing,
                  ),
                  child: Row(
                    children: [
                      Text(
                        action['icon'] ?? '',
                        style: MessageStyles.actionIconStyle,
                      ),
                      const SizedBox(width: MessageDimensions.spacing),
                      Text(
                        action['text'] ?? '',
                        style: MessageStyles.actionTextStyle,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}
