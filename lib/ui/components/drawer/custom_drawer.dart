import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seobi_app/ui/constants/app_dimensions.dart';
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(AppDimensions.borderRadiusLarge),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: AppDimensions.paddingMedium,
                ),
                child: Column(
                  children: [
                    // 상단 여백을 위한 Spacer
                    const Expanded(child: SizedBox()),
                    // 구분선
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                    SizedBox(height: AppDimensions.paddingMedium),
                    // 최하단 프로필 카드
                    _buildBottomProfile(viewModel),
                    // 하단 여백을 위한 Spacer
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomProfile(ProfileViewModel viewModel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ProfileCard(
            roleBackgroundColor: AppColors.main100,
            onProfileTap: _handleProfileTap,
          ),
        ),
        viewModel.isLoggedIn
            ? IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _handleSignOut,
              tooltip: '로그아웃',
            )
            : IconButton(
              icon: const Icon(Icons.login),
              onPressed: _handleSignIn,
              tooltip: '로그인',
            ),
      ],
    );
  }
}
