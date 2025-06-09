import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'message_styles.dart';

class FoldableMessage extends StatefulWidget {
  final String title;
  final List<String> content;
  final IconData titleIcon;
  final bool isError;
  final Widget Function(List<String>)? customContentBuilder;
  
  const FoldableMessage({
    super.key,
    required this.title,
    required this.content,
    required this.titleIcon,
    this.isError = false,
    this.customContentBuilder,
  });

  @override
  State<FoldableMessage> createState() => _FoldableMessageState();
}

class _FoldableMessageState extends State<FoldableMessage> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: MessageStyles.messagePadding,
      decoration: BoxDecoration(
        border: Border(          left: BorderSide(
            color: widget.isError ? Colors.red : MessageStyles.leftBorderColor,
            width: MessageStyles.borderWidth,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: _toggleExpanded,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타이틀 영역
            Row(
              children: [
                Icon(widget.titleIcon, size: 16, 
                  color: widget.isError ? Colors.red : AppColors.gray100
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: MessageStyles.labelTextStyle.copyWith(
                    color: widget.isError ? Colors.red : AppColors.gray100,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: AppColors.gray80,
                ),
              ],
            ),
            // 컨텐트 영역
            AnimatedSize(
              duration: MessageStyles.expandDuration,
              curve: Curves.easeInOut,
              child: Visibility(
                visible: _isExpanded,
                maintainState: true,
                maintainAnimation: true,
                child: Padding(                  padding: const EdgeInsets.only(top: 12),
                  child: widget.customContentBuilder != null
                      ? widget.customContentBuilder!(widget.content)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: widget.content.map((text) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              text,
                              style: MessageStyles.monospaceTextStyle.copyWith(
                                color: widget.isError ? Colors.red.shade700 : null,
                              ),
                            ),
                          )).toList(),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
