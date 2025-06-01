import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/text_placeholder.dart';
import 'profile_view_model.dart';
import 'role_badge.dart';

class ProfileCard extends StatefulWidget {
  final Color? roleBackgroundColor;
  final VoidCallback? onProfileTap;

  const ProfileCard({
    super.key,
    this.roleBackgroundColor = const Color(0xFFFF7A33),
    this.onProfileTap,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  late ProfileViewModel _viewModel;
  
  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileIcon(viewModel),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUserInfo(viewModel),
                    const SizedBox(height: 8),
                    _buildRoleTag(viewModel),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInfo(ProfileViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        viewModel.isLoggedIn && viewModel.name != null && viewModel.name!.isNotEmpty
            ? Text(
              viewModel.name!,
              style: const TextStyle(
                color: Color(0xFF4F4F4F),
                fontSize: 20,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                letterSpacing: -0.10,
              ),
            )
            : const TextPlaceholder(fontSize: 20, characterCount: 6),
        const SizedBox(height: 1),
        viewModel.isLoggedIn && viewModel.email != null && viewModel.email!.isNotEmpty
            ? Text(
              viewModel.email!,
              style: const TextStyle(
                color: Color(0xFF4F4F4F),
                fontSize: 12,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                letterSpacing: -0.06,
              ),
            )
            : const TextPlaceholder(fontSize: 12, characterCount: 15),
      ],
    );
  }

  Widget _buildRoleTag(ProfileViewModel viewModel) {
    if (!viewModel.isLoggedIn) {
      return const SizedBox.shrink();
    }
    return RoleBadge(role: viewModel.role ?? '일반', backgroundColor: widget.roleBackgroundColor);
  }

  Widget _buildProfileIcon(ProfileViewModel viewModel) {
    return GestureDetector(
      onTap: widget.onProfileTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: viewModel.isLoggedIn && viewModel.profileImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(27.5),
                child: Image.network(
                  viewModel.profileImageUrl!,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person_outline,
                      color: Colors.grey,
                    );
                  },
                ),
              )
            : const Icon(Icons.person_outline, color: Colors.grey),
      ),
    );
  }
}
