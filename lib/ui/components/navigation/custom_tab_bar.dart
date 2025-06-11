import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';

class CustomTabBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: AppDimensions.paddingSmall,
      ),
      padding: EdgeInsets.all(AppDimensions.paddingSmall * 0.5),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLarge),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            left: selectedIndex * (AppDimensions.buttonHeightMedium + AppDimensions.paddingSmall),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              width: AppDimensions.buttonHeightMedium,
              height: AppDimensions.buttonHeightMedium,
              decoration: BoxDecoration(
                color: Theme.of(context).tabBarTheme.indicatorColor,
                borderRadius: _getBorderRadius(selectedIndex),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => _buildTab(context, index)),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(left: index > 0 ? AppDimensions.paddingSmall : 0),
        child: SizedBox(
          width: AppDimensions.buttonHeightMedium,
          height: AppDimensions.buttonHeightMedium,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Icon(
                _getIcon(index),
                key: ValueKey<bool>(selectedIndex == index),
                color:
                    selectedIndex == index
                        ? Theme.of(context).tabBarTheme.labelColor
                        : Theme.of(context).tabBarTheme.unselectedLabelColor,
                size: AppDimensions.iconSizeMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius(int index) {
    if (index == 0) {
      return BorderRadius.only(
        topLeft: Radius.circular(AppDimensions.borderRadiusLarge),
        topRight: Radius.circular(AppDimensions.borderRadiusSmall),
        bottomLeft: Radius.circular(AppDimensions.borderRadiusLarge),
        bottomRight: Radius.circular(AppDimensions.borderRadiusSmall),
      );
    } else if (index == 2) {
      return BorderRadius.only(
        topLeft: Radius.circular(AppDimensions.borderRadiusSmall),
        topRight: Radius.circular(AppDimensions.borderRadiusLarge),
        bottomLeft: Radius.circular(AppDimensions.borderRadiusSmall),
        bottomRight: Radius.circular(AppDimensions.borderRadiusLarge),
      );
    }
    return BorderRadius.circular(AppDimensions.borderRadiusSmall);
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.chat_bubble_outline;
      case 1:
        return Icons.inbox_outlined;
      case 2:
        return Icons.bar_chart_outlined;
      default:
        return Icons.chat_bubble_outline;
    }
  }
}
