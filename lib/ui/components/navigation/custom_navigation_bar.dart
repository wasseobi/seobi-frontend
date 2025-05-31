import 'package:flutter/material.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import '../common/custom_button.dart';
import 'custom_tab_bar.dart';
import 'date_indicator.dart';

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
      padding: const EdgeInsets.only(left: 10, right: 23),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 중앙 탭바
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: CustomTabBar(
                selectedIndex: selectedTabIndex,
                onTap: onTabChanged,
              ),
            ),
          ),

          // 좌측 햄버거 버튼
          Align(
            alignment: Alignment.centerLeft,
            child: CustomButton(
              icon: Icons.menu,
              onPressed: onMenuPressed,
              iconColor: AppColors.navOpenSidebar,
              type: CustomButtonType.transparent,
              size: 50,
              iconSize: 24,
            ),
          ),

          // 우측 날짜 표시
          Align(
            alignment: Alignment.centerRight,
            child: DateIndicator(date: '5월 28일', dayOfWeek: '수요일'),
          ),
        ],
      ),
    );
  }
}
