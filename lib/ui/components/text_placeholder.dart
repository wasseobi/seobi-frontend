import 'package:flutter/material.dart';

class TextPlaceholder extends StatefulWidget {
  final double fontSize;
  final int characterCount;
  final Color? color;
  final double? borderRadius;
  final double? height;
  final bool enableShimmer;

  const TextPlaceholder({
    super.key,
    required this.fontSize,
    required this.characterCount,
    this.color,
    this.borderRadius = 4.0,
    this.height,
    this.enableShimmer = true,
  });

  @override
  State<TextPlaceholder> createState() => _TextPlaceholderState();
}

class _TextPlaceholderState extends State<TextPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.ease),
    );

    if (widget.enableShimmer) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calculatedWidth = widget.fontSize * widget.characterCount * 0.7;
    final calculatedHeight = widget.height ?? widget.fontSize * 1.2;

    return Container(
      width: calculatedWidth,
      height: calculatedHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 4.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 4.0),
        child:
            widget.enableShimmer
                ? AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops:
                              [
                                _animation.value - 0.3,
                                _animation.value,
                                _animation.value + 0.3,
                              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                          colors: [
                            widget.color ?? Colors.grey[300]!,
                            Colors.white.withOpacity(0.8),
                            widget.color ?? Colors.grey[300]!,
                          ],
                        ),
                      ),
                    );
                  },
                )
                : Container(color: widget.color ?? Colors.grey[300]),
      ),
    );
  }
}
