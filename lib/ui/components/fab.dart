import 'package:flutter/material.dart';

class ChatFloatingBar extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onCollapse;
  final VoidCallback onSend;
  final TextEditingController controller;
  final FocusNode focusNode;

  const ChatFloatingBar({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.onCollapse,
    required this.onSend,
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
            final double expandedWidth = maxAvailableWidth.clamp(300, 600);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isExpanded ? expandedWidth : 88,
              height: isExpanded ? 205 : 88,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isExpanded ? 12 : 44),
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
    return GestureDetector(
      onTap: onToggle,
      child: const Center(
        child: Icon(Icons.chat_bubble_outline, color: Colors.black87, size: 32),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(focusNode.context!).unfocus();
        onCollapse();
      },
      child: Padding(
        padding: const EdgeInsets.only(
          top: 24,
          left: 23,
          right: 16,
          bottom: 13,
        ),
        child: SingleChildScrollView(
          // ✅ 추가된 부분
          child: Column(
            mainAxisSize: MainAxisSize.min, // ✅ 꼭 같이 설정
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7D7D7D),
                  letterSpacing: -0.1,
                ),
                decoration: const InputDecoration(
                  hintText: '질문을 입력하거나, 일정을 등록하거나 Seobi 에게 업무를 시켜 보세요.',
                  hintStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7D7D7D),
                    letterSpacing: -0.1,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12), // Spacer 대신 사용
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.attach_file,
                    color: const Color(0xFFF6F6F6),
                  ),
                  Row(
                    children: [
                      _buildCircleButton(
                        icon: Icons.keyboard_voice,
                        color: const Color(0xFFFF7A33),
                        iconColor: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      _buildCircleButton(
                        icon: Icons.send,
                        color: const Color(0xFFF6F6F6),
                        onTap: onSend,
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
    Color iconColor = Colors.black,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: ShapeDecoration(
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Center(child: Icon(icon, size: 24, color: iconColor)),
      ),
    );
  }
}
