import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:seobi_app/ui/components/common/custom_button.dart';
import 'package:seobi_app/services/auth/auth_service.dart';
import '../../constants/app_colors.dart';
import '../profile_card/profile_card.dart';
=======
import 'package:provider/provider.dart';
import 'package:seobi_app/ui/components/common/custom_button.dart';
import '../../constants/app_colors.dart';
import 'profile_card/profile_card.dart';
import 'profile_card/profile_view_model.dart';
>>>>>>> origin/feature/integrate-ui-service
import '../auth/sign_in_bottom_sheet.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
<<<<<<< HEAD
  final AuthService _authService = AuthService();
  bool _isLoggedIn = false;
=======
  late ProfileViewModel _profileViewModel;
>>>>>>> origin/feature/integrate-ui-service

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _loadAuthState();
    _authService.addListener(_loadAuthState);
=======
    _profileViewModel = ProfileViewModel();
>>>>>>> origin/feature/integrate-ui-service
  }

  @override
  void dispose() {
<<<<<<< HEAD
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

=======
    _profileViewModel.dispose();
    super.dispose();
  }

>>>>>>> origin/feature/integrate-ui-service
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
<<<<<<< HEAD
    await _authService.signOut();
=======
    await _profileViewModel.signOut();
>>>>>>> origin/feature/integrate-ui-service
  }

  void _handleProfileTap() {
    // 프로필 탭 처리 (필요시 구현)
    debugPrint('프로필 카드가 탭되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
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
=======
    return ChangeNotifierProvider.value(
      value: _profileViewModel,
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, _) {
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
                  _buildBottomProfile(viewModel),
                  // 하단 여백을 위한 Spacer
                  SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
>>>>>>> origin/feature/integrate-ui-service
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildBottomProfile() {
=======
  Widget _buildBottomProfile(ProfileViewModel viewModel) {
>>>>>>> origin/feature/integrate-ui-service
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
<<<<<<< HEAD
          _isLoggedIn
=======
          viewModel.isLoggedIn
>>>>>>> origin/feature/integrate-ui-service
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
