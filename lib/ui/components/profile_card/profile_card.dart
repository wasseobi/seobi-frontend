import 'package:flutter/material.dart';
import 'package:seobi_app/services/auth/auth_service.dart';
import '../common/text_placeholder.dart';
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
  final AuthService _authService = AuthService();
  String? _name;
  String? _email;
  String? _profileImageUrl;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _authService.addListener(_loadUserData);
  }

  @override
  void dispose() {
    _authService.removeListener(_loadUserData);
    super.dispose();
  }

  void _loadUserData() {
    if (mounted) {
      setState(() {
        _isLoggedIn = _authService.isLoggedIn;
        _name = _authService.displayName;
        _email = _authService.userEmail;
        _profileImageUrl = _authService.photoUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfileIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserInfo(),
              const SizedBox(height: 8),
              _buildRoleTag(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _isLoggedIn && _name != null && _name!.isNotEmpty
            ? Text(
              _name!,
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
        _isLoggedIn && _email != null && _email!.isNotEmpty
            ? Text(
              _email!,
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

  Widget _buildRoleTag() {
    if (!_isLoggedIn) {
      return const SizedBox.shrink();
    }
    return RoleBadge(role: '일반', backgroundColor: widget.roleBackgroundColor);
  }

  Widget _buildProfileIcon() {
    return GestureDetector(
      onTap: widget.onProfileTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child:
            _isLoggedIn && _profileImageUrl != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(27.5),
                  child: Image.network(
                    _profileImageUrl!,
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
