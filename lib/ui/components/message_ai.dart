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
  final VoidCallback? onTtsPlay;
  final bool isStreaming; // 스트리밍 중인지 여부

  const AssistantMessage({
    super.key,
    required this.message,
    this.type = 'text',
    this.actions,
    this.card,
    this.timestamp,
    this.onTtsPlay,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 0, right: 50),
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(),
          if ((type == 'card' && card != null) ||
              (actions != null && actions!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
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
                        ),
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
            ),
          if (timestamp != null)
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child:
                message.isEmpty && isStreaming
                    ? _buildTypingIndicator()
                    : Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
          ),
          // TTS 아이콘은 스트리밍 중이 아니고 메시지가 있을 때만 표시
          if (!isStreaming && message.isNotEmpty && onTtsPlay != null)
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: onTtsPlay,
              color: Colors.black87,
              iconSize: 20,
            ),
          // 스트리밍 중일 때는 로딩 인디케이터 표시
          if (isStreaming && message.isNotEmpty)
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(left: 8),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '서비가 응답 중입니다.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ],
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
                        style: const TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: MessageDimensions.spacing),
                      Text(
                        action['text'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
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
