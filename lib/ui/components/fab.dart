import 'package:flutter/material.dart';

class ChatFloatingBar extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onCollapse;
  final VoidCallback onSend;
  final VoidCallback onVoiceInput;
  final bool isListening;
  final bool isPlaying;
  final TextEditingController controller;
  final FocusNode focusNode;

  const ChatFloatingBar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.onCollapse,
    required this.onSend,
    required this.onVoiceInput,
    required this.isListening,
    required this.isPlaying,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 화면 크기에 따른 동적 계산
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final double maxWidth = screenWidth * 0.9; // 화면의 90%
            final double minWidth = 56.0;
            final double maxExpandedWidth = 600.0;

            // 실제 사용할 너비 계산
            final double expandedWidth = maxWidth.clamp(
              300.0,
              maxExpandedWidth,
            );
            final double buttonSize =
                (expandedWidth - 32 - 16) / 6; // 패딩과 간격 고려
            final double maxHeight = screenHeight * 0.4; // 화면 높이의 40%까지 허용

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isExpanded ? expandedWidth : minWidth,
              constraints: BoxConstraints(
                minHeight: minWidth,
                maxHeight: isExpanded ? maxHeight : minWidth,
              ),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isExpanded ? 12 : 28),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child:
                  isExpanded
                      ? _buildExpandedContent(
                        expandedWidth,
                        buttonSize,
                        maxHeight,
                      )
                      : _buildCollapsedButton(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCollapsedButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(28),
        child: const Center(
          child: Icon(
            Icons.chat_bubble_outline,
            color: Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    double expandedWidth,
    double buttonSize,
    double maxHeight,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          FocusScope.of(focusNode.context!).unfocus();
          onCollapse();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 13),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: expandedWidth - 32,
                      maxHeight: maxHeight - 100, // 버튼 영역과 패딩을 고려한 높이
                    ),
                    child: TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF7D7D7D),
                        letterSpacing: -0.1,
                      ),
                      decoration: const InputDecoration(
                        hintText: '질문을 입력하거나, 일정을 등록하거나 Seobi 에게 업무를 시켜 보세요.',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF7D7D7D),
                          letterSpacing: -0.1,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: expandedWidth - 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: buttonSize,
                      height: buttonSize,
                      child: _buildActionButton(
                        icon: Icons.attach_file,
                        color: const Color(0xFFF6F6F6),
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: buttonSize,
                          height: buttonSize,
                          child: _buildActionButton(
                            icon:
                                isListening ? Icons.mic : Icons.keyboard_voice,
                            color:
                                isListening
                                    ? const Color(0xFFFF7A33)
                                    : const Color(0xFFF6F6F6),
                            iconColor:
                                isListening ? Colors.white : Colors.black,
                            onTap: onVoiceInput,
                          ),
                        ),
                        SizedBox(width: buttonSize / 4),
                        SizedBox(
                          width: buttonSize,
                          height: buttonSize,
                          child: _buildActionButton(
                            icon: Icons.send,
                            color: const Color(0xFFF6F6F6),
                            onTap:
                                controller.text.trim().isEmpty ? null : onSend,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    Color iconColor = Colors.black,
    VoidCallback? onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(child: Icon(icon, size: 18, color: iconColor)),
        ),
      ),
    );
  }
}
