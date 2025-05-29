import 'package:flutter/material.dart';
import 'package:seobi_app/ui/components/custom_button.dart';
import 'package:seobi_app/services/auth/auth_service.dart';
import '../constants/app_colors.dart';
import 'profile_card.dart';
import 'sign_in_bottom_sheet.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadAuthState();
    _authService.addListener(_loadAuthState);
  }

  @override
  void dispose() {
    _authService.removeListener(_loadAuthState);
    super.dispose();
  }

  void _loadAuthState() async {
    // 스토리지 업데이트가 완료될 때까지 잠시 대기
    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      setState(() {
        _isLoggedIn = _authService.isLoggedIn;
      });
    }
  }

  Future<void> _handleSignIn() async {
    // 바텀 시트 열기
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SignInBottomSheet(),
    );
  }

  Future<void> _handleSignOut() async {
    // 로그아웃 처리
    await _authService.signOut();
  }

  void _handleProfileTap() {
    // 프로필 탭 처리 (필요시 구현)
    debugPrint('프로필 카드가 탭되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 340,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
      ),
      backgroundColor: AppColors.containerLight,
      child: SafeArea(
        child: Column(
          children: [
            // 상단 여백을 위한 Spacer
            const Expanded(child: SizedBox()),
            // 구분선
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 33, vertical: 13),
              child: Divider(height: 1, thickness: 1, color: AppColors.main80),
            ),
            // 최하단 프로필 카드
            _buildBottomProfile(),
            // 하단 여백을 위한 Spacer
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ProfileCard(
              roleBackgroundColor: AppColors.main100,
              onProfileTap: _handleProfileTap,
            ),
          ),
          _isLoggedIn
              ? CustomButton(
                icon: Icons.logout,
                onPressed: _handleSignOut,
                iconColor: AppColors.gray80,
                tooltip: '로그아웃',
              )
              : CustomButton(
                icon: Icons.login,
                onPressed: _handleSignIn,
                iconColor: AppColors.gray80,
                tooltip: '로그인',
              ),
        ],
      ),
    );
  }
}
