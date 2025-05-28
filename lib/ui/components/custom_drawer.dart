import 'package:flutter/material.dart';
import 'package:seobi_app/ui/components/custom_button.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'google_sign_in_button.dart';
import 'profile_card.dart';

class CustomDrawer extends StatefulWidget {
  final VoidCallback? onSignInPressed;
  final VoidCallback? onSignOutPressed;
  final VoidCallback? onProfileTap;
  final bool isLoggedIn;
  final String? userName;
  final String? userEmail;
  final String? profileImageUrl;

  const CustomDrawer({
    super.key,
    this.onSignInPressed,
    this.onSignOutPressed,
    this.onProfileTap,
    this.isLoggedIn = false,
    this.userName,
    this.userEmail,
    this.profileImageUrl,
  });

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 340,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
      ),
      child: Container(
        height: 932,
        decoration: const BoxDecoration(gradient: AppGradients.lightBG),
        child: SafeArea(
          child: Container(
            child: Column(
              children: [
                // 상단 여백을 위한 Spacer
                const Expanded(child: SizedBox()),
                // 최하단 프로필 카드
                _buildBottomProfile(),
              ],
            ),
          ),
        ),
      ),
    );
  }  Widget _buildBottomProfile() {
    if (!widget.isLoggedIn || widget.userName == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '로그인하여 더 많은\n기능을 이용해보세요',
            textAlign: TextAlign.center,
            style: PretendardStyles.semiBold14.copyWith(
              color: AppColors.textLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GoogleSignInButton(
              onPressed: widget.onSignInPressed ?? () {},
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ProfileCard(
              name: widget.userName!,
              email: widget.userEmail ?? '',
              role: '일반 사용자',
              profileImageUrl: widget.profileImageUrl,
              roleBackgroundColor: AppColors.main100,
              onProfileTap: widget.onProfileTap,
            ),
          ),
          CustomButton(
            icon: Icons.logout,
            onPressed: widget.onSignOutPressed ?? () {},
            iconColor: AppColors.gray80,
            tooltip: '로그아웃',
          ),
        ],
      ),
    );
  }
}
