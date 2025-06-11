import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
import 'custom_tab_bar.dart';
import 'date_indicator/date_indicator.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedTabIndex;
  final Function(int) onTabChanged;
  final VoidCallback? onMenuPressed;

  const CustomNavigationBar({
    super.key,
    required this.selectedTabIndex,
    required this.onTabChanged,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSmall,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 중앙 탭바
          Center(
            child: CustomTabBar(
              selectedIndex: selectedTabIndex,
              onTap: onTabChanged,
            ),
          ),

          // 좌측 햄버거 버튼
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu),
            ),
          ), // 우측 날짜 표시
          Align(alignment: Alignment.centerRight, child: DateIndicator()),
        ],
      ),
    );
  }
}
