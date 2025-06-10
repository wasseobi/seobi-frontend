import 'package:flutter/material.dart';
import '../../constants/dimensions/tab_dimensions.dart';

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
      padding: EdgeInsets.all(TabDimensions.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: selectedIndex * (TabDimensions.size + TabDimensions.spacing),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: TabDimensions.size,
              height: TabDimensions.size,
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
        padding: EdgeInsets.only(left: index > 0 ? TabDimensions.spacing : 0),
        child: SizedBox(
          width: TabDimensions.size,
          height: TabDimensions.size,
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
                size: TabDimensions.iconSize,
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
        topLeft: Radius.circular(TabDimensions.radiusLarge),
        topRight: Radius.circular(TabDimensions.radiusSmall),
        bottomLeft: Radius.circular(TabDimensions.radiusLarge),
        bottomRight: Radius.circular(TabDimensions.radiusSmall),
      );
    } else if (index == 2) {
      return BorderRadius.only(
        topLeft: Radius.circular(TabDimensions.radiusSmall),
        topRight: Radius.circular(TabDimensions.radiusLarge),
        bottomLeft: Radius.circular(TabDimensions.radiusSmall),
        bottomRight: Radius.circular(TabDimensions.radiusLarge),
      );
    }
    return BorderRadius.circular(TabDimensions.radiusSmall);
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
