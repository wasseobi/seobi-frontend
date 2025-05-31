import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';

enum CustomButtonType {
  transparent,
  circular
}

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final CustomButtonType type;
  final double size;
  final double iconSize;
  final String? tooltip;

  const CustomButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.backgroundColor,
    this.type = CustomButtonType.transparent,
    this.size = 50,
    this.iconSize = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final buttonChild = Icon(
      icon,
      size: iconSize,
      color: iconColor ?? AppColors.iconLight,
    );

    return SizedBox(
      width: size,
      height: size,
      child: type == CustomButtonType.transparent
          ? IconButton(
              padding: EdgeInsets.zero,
              icon: buttonChild,
              onPressed: onPressed,
              tooltip: tooltip,
            )
          : Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor ?? Theme.of(context).primaryColor,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: Center(child: buttonChild),
                ),
              ),
            ),
    );
  }
}