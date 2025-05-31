import 'package:flutter/material.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const RoleBadge({
    super.key,
    required this.role,
    this.backgroundColor = const Color(0xFFFF7A33),
    this.textColor = Colors.white,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    this.borderRadius = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 7),
        ),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontFamily: 'Pretendard',
          fontWeight: fontWeight,
          letterSpacing: -0.06,
        ),
      ),
    );
  }
}
