import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../constants/app_colors.dart';
import '../constants/dimensions/message_dimensions.dart';
import 'card_schedule.dart';

enum MessageWorkType {
  normal, // 일반 텍스트
  searching, // 🔍 검색 중
  processing, // 🛠️ 도구 실행 중
  found, // ✅ 결과 찾음
  preparing, // 서비가 준비 중
  responding, // 실시간 응답 중
}

class AssistantMessage extends StatefulWidget {
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
  State<AssistantMessage> createState() => _AssistantMessageState();
}

class _AssistantMessageState extends State<AssistantMessage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 애니메이션이 필요한 경우 시작
    _startAnimationIfNeeded();
  }

  void _startAnimationIfNeeded() {
    final workType = _detectWorkType();
    if (_shouldAnimate(workType)) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AssistantMessage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 메시지나 스트리밍 상태가 변경되면 애니메이션 재평가
    if (oldWidget.message != widget.message ||
        oldWidget.isStreaming != widget.isStreaming) {
      _animationController.reset();
      _startAnimationIfNeeded();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 메시지 내용으로 작업 타입 감지
  MessageWorkType _detectWorkType() {
    if (widget.message.isEmpty && widget.isStreaming) {
      return MessageWorkType.responding;
    }

    if (widget.message.contains('🔍') && widget.message.contains('검색')) {
      return MessageWorkType.searching;
    }

    if (widget.message.contains('🛠️') && widget.message.contains('도구를 실행')) {
      return MessageWorkType.processing;
    }

    if (widget.message.contains('✅') && widget.message.contains('결과를 찾았습니다')) {
      return MessageWorkType.found;
    }

    if (widget.message.contains('서비가') &&
        (widget.message.contains('준비') || widget.message.contains('답변을 준비'))) {
      return MessageWorkType.preparing;
    }

    if (widget.isStreaming && widget.message.isNotEmpty) {
      return MessageWorkType.responding;
    }

    return MessageWorkType.normal;
  }

  // 애니메이션이 필요한지 확인
  bool _shouldAnimate(MessageWorkType workType) {
    return workType == MessageWorkType.searching ||
        workType == MessageWorkType.processing ||
        workType == MessageWorkType.preparing ||
        workType == MessageWorkType.responding;
  }

  // 작업 타입별 아이콘 반환
  Widget _getWorkIcon(MessageWorkType workType) {
    switch (workType) {
      case MessageWorkType.searching:
        return _buildAnimatedIcon(
          Icons.search,
          Colors.blue,
          shouldAnimate: true,
        );

      case MessageWorkType.processing:
        return _buildAnimatedIcon(
          Icons.settings,
          Colors.orange,
          shouldAnimate: true,
        );

      case MessageWorkType.found:
        return _buildAnimatedIcon(
          Icons.check_circle,
          Colors.green,
          shouldAnimate: false,
        );

      case MessageWorkType.preparing:
        return _buildAnimatedIcon(
          Icons.psychology,
          Colors.purple,
          shouldAnimate: true,
        );

      case MessageWorkType.responding:
        return _buildAnimatedIcon(
          Icons.chat_bubble,
          Colors.blue,
          shouldAnimate: true,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // 애니메이션 아이콘 빌더
  Widget _buildAnimatedIcon(
    IconData icon,
    Color color, {
    required bool shouldAnimate,
  }) {
    if (!shouldAnimate) {
      return Icon(icon, color: color, size: 20);
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            icon,
            color: color.withOpacity(0.6 + (_scaleAnimation.value - 0.8) * 0.5),
            size: 18 + (_scaleAnimation.value - 0.8) * 5,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 0, right: 50),
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(),
          if ((widget.type == 'card' && widget.card != null) ||
              (widget.actions != null && widget.actions!.isNotEmpty))
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
                      if (widget.type == 'card' && widget.card != null)
                        ScheduleCard(
                          title: widget.card!['title'] ?? '',
                          time: widget.card!['time'] ?? '',
                          location: widget.card!['location'] ?? '',
                        ),
                      if (widget.actions != null && widget.actions!.isNotEmpty)
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
          if (widget.timestamp != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.timestamp!,
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
    final workType = _detectWorkType();
    final showIcon = workType != MessageWorkType.normal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.gray20,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[_getWorkIcon(workType), const SizedBox(width: 12)],
          Flexible(
            child:
                widget.message.isEmpty && widget.isStreaming
                    ? _buildTypingIndicator()
                    : widget.isStreaming
                    ? _buildStreamingText()
                    : _buildMarkdownText(),
          ),
          // TTS 버튼은 스트리밍 완료된 메시지에만 표시
          if (!widget.isStreaming &&
              widget.message.isNotEmpty &&
              widget.onTtsPlay != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onTtsPlay,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.volume_up,
                    color: AppColors.iconLight,
                    size: 20,
                  ),
                ),
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
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textLightSecondary,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gray80),
          ),
        ),
      ],
    );
  }

  Widget _buildStreamingText() {
    // 스트리밍 중에는 원본 텍스트 표시 (마크다운 적용 없음)
    return Text(
      widget.message,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.textLightPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMarkdownText() {
    // 완료 후에는 마크다운 렌더링 적용
    return MarkdownBody(
      data: widget.message,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 16,
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.w500,
        ),
        h1: const TextStyle(
          fontSize: 20,
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.bold,
        ),
        h2: const TextStyle(
          fontSize: 18,
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.bold,
        ),
        h3: const TextStyle(
          fontSize: 16,
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.bold,
        ),
        strong: const TextStyle(
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.bold,
        ),
        em: const TextStyle(
          color: AppColors.textLightPrimary,
          fontStyle: FontStyle.italic,
        ),
        code: TextStyle(
          backgroundColor: AppColors.gray20,
          color: AppColors.textLightPrimary,
          fontFamily: 'monospace',
        ),
        listBullet: const TextStyle(color: AppColors.textLightPrimary),
      ),
      selectable: true,
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          widget.actions!
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
