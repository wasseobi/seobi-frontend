import 'package:flutter/material.dart';
import 'package:flutter_dash/flutter_dash.dart';

/// 세션 구분선 위젯 (점선만)
class SessionDivider extends StatelessWidget {
  final String sessionId;
  final String? sessionTitle; // 호환성을 위해 유지하지만 사용하지 않음
  final Color? color;
  final double dashLength;
  final double dashGap;
  final double thickness;
  final EdgeInsets padding;

  const SessionDivider({
    Key? key,
    required this.sessionId,
    this.sessionTitle,
    this.color,
    this.dashLength = 3.0,
    this.dashGap = 2.0,
    this.thickness = 0.8,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = color ?? theme.dividerColor.withAlpha(102);
    
    return Container(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Dash(
            direction: Axis.horizontal,
            length: constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0,
            dashLength: dashLength,
            dashGap: dashGap,
            dashColor: dividerColor,
            dashThickness: thickness,
          );
        },
      ),
    );
  }
}
