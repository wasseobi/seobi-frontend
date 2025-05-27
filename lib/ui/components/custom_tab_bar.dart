import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';

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
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      padding: EdgeInsets.all(AppDimens.tabPadding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimens.containerRadius),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: selectedIndex * (AppDimens.tabSize + AppDimens.tabSpacing),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: AppDimens.tabSize,
              height: AppDimens.tabSize,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: _getBorderRadius(selectedIndex),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) => _buildTab(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(left: index > 0 ? AppDimens.tabSpacing : 0),
        child: SizedBox(
          width: AppDimens.tabSize,
          height: AppDimens.tabSize,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Icon(
                _getIcon(index),
                key: ValueKey<bool>(selectedIndex == index),
                color: selectedIndex == index
                    ? AppColors.primary
                    : AppColors.white,
                size: AppDimens.tabIconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius(int index) {
    if (index == 0) {
      return const BorderRadius.horizontal(
        left: Radius.circular(AppDimens.tabRadiusLarge),
        right: Radius.circular(AppDimens.tabRadiusSmall),
      );
    } else if (index == 2) {
      return const BorderRadius.horizontal(
        left: Radius.circular(AppDimens.tabRadiusSmall),
        right: Radius.circular(AppDimens.tabRadiusLarge),
      );
    }
    return BorderRadius.circular(AppDimens.tabRadiusSmall);
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
