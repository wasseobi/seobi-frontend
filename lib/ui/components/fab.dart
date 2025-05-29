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
            final double maxAvailableWidth = constraints.maxWidth;
            final double expandedWidth =
                maxAvailableWidth.clamp(300, 600).toDouble();

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isExpanded ? expandedWidth : 56,
              height: isExpanded ? 205 : 56,
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
                      ? _buildExpandedContent()
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

  Widget _buildExpandedContent() {
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
              TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 2,
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
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionButton(
                    icon: Icons.attach_file,
                    color: const Color(0xFFF6F6F6),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: isListening ? Icons.mic : Icons.keyboard_voice,
                        color:
                            isListening
                                ? const Color(0xFFFF7A33)
                                : const Color(0xFFF6F6F6),
                        iconColor: isListening ? Colors.white : Colors.black,
                        onTap: onVoiceInput,
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.send,
                        color: const Color(0xFFF6F6F6),
                        onTap: controller.text.trim().isEmpty ? null : onSend,
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
