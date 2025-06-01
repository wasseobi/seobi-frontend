import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seobi_app/ui/components/common/custom_button.dart';
import '../../constants/app_colors.dart';
import 'profile_card/profile_card.dart';
import 'profile_card/profile_view_model.dart';
import '../auth/sign_in_bottom_sheet.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late ProfileViewModel _profileViewModel;

  @override
  void initState() {
    super.initState();
    _profileViewModel = ProfileViewModel();
  }

  @override
  void dispose() {
    _profileViewModel.dispose();
    super.dispose();
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
    await _profileViewModel.signOut();
  }

  void _handleProfileTap() {
    // 프로필 탭 처리 (필요시 구현)
    debugPrint('프로필 카드가 탭되었습니다.');
  }

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }

  Widget _buildBottomProfile(ProfileViewModel viewModel) {
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
          viewModel.isLoggedIn
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
