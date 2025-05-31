import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;

/// 위젯의 크기를 측정하고 크기가 변경될 때 콜백을 호출하는 위젯
class MeasureSize extends StatefulWidget {
  final Widget child;
  final Function(Size size) onChange;

  const MeasureSize({
    Key? key,
    required this.onChange,
    required this.child,
  }) : super(key: key);

  @override
  State<MeasureSize> createState() => _MeasureSizeState();
}

class _MeasureSizeState extends State<MeasureSize> {
  Size? _oldSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 위젯이 렌더링된 후 크기 측정
          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final size = renderBox.size;
            if (_oldSize == null || _oldSize != size) {
              _oldSize = size;
              widget.onChange(size);
            }
          }
        });
        return widget.child;
      },
    );
  }
}
