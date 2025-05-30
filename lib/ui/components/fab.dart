import 'package:flutter/material.dart';
import '../../services/conversation/chat_service.dart';
import '../../repositories/backend/models/message.dart';
import '../../services/auth/auth_service.dart';
import '../../services/tts/tts_service.dart';
import '../constants/dimensions/app_dimensions.dart';
import '../constants/app_colors.dart';

class ChatFloatingBar extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onCollapse;
  final Function(Message)? onMessageSent;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const ChatFloatingBar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.onCollapse,
    this.onMessageSent,
    this.controller,
    this.focusNode,
  });

  @override
  State<ChatFloatingBar> createState() => _ChatFloatingBarState();
}

class _ChatFloatingBarState extends State<ChatFloatingBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TtsService _ttsService = TtsService();

  bool _isListening = false;
  bool _isSending = false;
  String _displayText = '';
  String _confirmedText = '';
  String _pendingText = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    _controller.addListener(() {
      final newText = _controller.text;
      if (!_isListening && _displayText != newText) {
        setState(() {
          _displayText = newText;
          _confirmedText = newText;
        });
      }
    });
  }

  void _updateDisplayText() {
    String newDisplayText =
        _confirmedText.isEmpty
            ? _pendingText
            : '$_confirmedText $_pendingText'.trim();

    setState(() {
      _displayText = newDisplayText;
      _controller.value = TextEditingValue(
        text: newDisplayText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newDisplayText.length),
        ),
      );
    });
  }

  Future<void> _handleVoiceListen() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _confirmedText = _displayText;
        _pendingText = '';
        _updateDisplayText();
      });
    } else {
      // STT 시작 시 TTS 인터럽트
      debugPrint(
        '[FAB] STT 시작 전 TTS 상태 - isPlaying: ${_ttsService.isPlaying}, isPaused: ${_ttsService.isPaused}',
      );
      await _ttsService.interrupt();

      // TTS가 완전히 정지될 때까지 잠시 대기
      await Future.delayed(const Duration(milliseconds: 150));

      debugPrint(
        '[FAB] STT 시작 후 TTS 상태 - isPlaying: ${_ttsService.isPlaying}, isPaused: ${_ttsService.isPaused}, isInterrupted: ${_ttsService.isInterrupted}',
      );

      setState(() {
        _isListening = true;
        _pendingText = '';
        _updateDisplayText();
      });
    }

    await _chatService.toggleVoiceRecognition(
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() {
            if (isFinal) {
              _confirmedText =
                  _confirmedText.isEmpty ? text : '$_confirmedText $text';
              _pendingText = '';
            } else {
              _pendingText = text;
            }
            _updateDisplayText();
          });
        }
      },
      onSpeechComplete: () {
        if (mounted) {
          setState(() {
            _isListening = false;
            _confirmedText = _displayText;
            _pendingText = '';
            _updateDisplayText();
          });
        }
      },
    );
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    // 로그인 체크
    if (!_authService.isLoggedIn) {
      _showError('사용자 인증이 필요합니다.');
      return;
    }

    // 메시지 전송 시 TTS 인터럽트
    debugPrint('[FAB] 메시지 전송 시작 - TTS 인터럽트 실행');
    await _ttsService.interrupt();

    // TTS가 완전히 정지될 때까지 잠시 대기
    await Future.delayed(const Duration(milliseconds: 150));

    setState(() => _isSending = true);

    try {
      // 스트리밍 시작 전에 즉시 입력창 초기화
      await _clearInputCompletely();

      // 메시지 전송 (이미 입력창이 초기화된 상태에서 전송)
      await _chatService.sendMessage(text);
    } catch (e) {
      _showError('메시지 전송 중 오류가 발생했습니다: $e');
      setState(() => _isSending = false);
    }
  }

  /// 입력창을 완전히 초기화하는 메서드
  Future<void> _clearInputCompletely() async {
    // STT가 실행 중이면 중지
    if (_isListening) {
      await _chatService.toggleVoiceRecognition(
        onResult: (text, isFinal) {},
        onSpeechComplete: () {},
      );
    }

    setState(() {
      // 모든 텍스트 상태 초기화
      _displayText = '';
      _confirmedText = '';
      _pendingText = '';
      _isSending = false;
      _isListening = false;

      // 컨트롤러 초기화
      _controller.clear();
    });

    // 포커스 해제
    _focusNode.unfocus();

    // UI 업데이트 확인
    _updateDisplayText();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.fabBottomPadding),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxAvailableWidth = constraints.maxWidth;
            final double expandedWidth = maxAvailableWidth.clamp(
              AppDimensions.fabMinWidth,
              AppDimensions.fabMaxWidth,
            );

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width:
                  widget.isExpanded
                      ? expandedWidth
                      : AppDimensions.fabCollapsedSize,
              height:
                  widget.isExpanded
                      ? AppDimensions.fabExpandedHeight
                      : AppDimensions.fabCollapsedSize,
              decoration: ShapeDecoration(
                color: AppColors.containerLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    widget.isExpanded
                        ? AppDimensions.fabExpandedRadius
                        : AppDimensions.fabCollapsedRadius,
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:
                  widget.isExpanded
                      ? _buildExpandedContent()
                      : _buildCollapsedButton(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollapsedButton() {
    return GestureDetector(
      onTap: widget.onToggle,
      child: const Center(
        child: Icon(
          Icons.chat_bubble_outline,
          color: AppColors.iconLight,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
        widget.onCollapse();
      },
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppDimensions.fabContentPaddingTop,
          left: AppDimensions.fabContentPaddingLeft,
          right: AppDimensions.fabContentPaddingRight,
          bottom: AppDimensions.fabContentPaddingBottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 2,
                onSubmitted: (_) => _handleSend(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLightPrimary,
                  letterSpacing: -0.1,
                ),
                decoration: const InputDecoration(
                  hintText: '질문을 입력하거나, 일정을 등록하거나 Seobi 에게 업무를 시켜 보세요.',
                  hintStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLightSecondary,
                    letterSpacing: -0.1,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              SizedBox(height: AppDimensions.spacing12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.attach_file,
                    color: AppColors.gray20,
                    iconColor: AppColors.iconLight,
                  ),
                  Row(
                    children: [
                      _buildCircleButton(
                        icon: _isListening ? Icons.stop : Icons.keyboard_voice,
                        color:
                            _isListening
                                ? AppColors.error100
                                : AppColors.main100,
                        iconColor: AppColors.white100,
                        onTap: _handleVoiceListen,
                      ),
                      SizedBox(width: AppDimensions.spacing10),
                      _buildCircleButton(
                        icon: Icons.send,
                        color: AppColors.gray20,
                        iconColor: AppColors.iconLight,
                        onTap: _handleSend,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    Color iconColor = AppColors.iconLight,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.circleButtonSize,
        height: AppDimensions.circleButtonSize,
        decoration: ShapeDecoration(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radius24),
          ),
        ),
        child: Center(child: Icon(icon, size: 24, color: iconColor)),
      ),
    );
  }
}
