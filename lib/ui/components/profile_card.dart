import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String? profileImageUrl;
  final Color roleBackgroundColor;
  final VoidCallback? onProfileTap;

  const ProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
    this.roleBackgroundColor = const Color(0xFFFF7A33),
    this.onProfileTap,
  });
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
        Text(
          name,
          style: const TextStyle(
            color: Color(0xFF4F4F4F),
            fontSize: 20,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.10,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          email,
          style: const TextStyle(
            color: Color(0xFF4F4F4F),
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            letterSpacing: -0.06,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: ShapeDecoration(
        color: roleBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
          letterSpacing: -0.06,
        ),
      ),
    );
  }
  Widget _buildProfileIcon() {
    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: profileImageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(27.5),
                child: Image.network(
                  profileImageUrl!,
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person_outline, color: Colors.grey);
                  },
                ),
              )
            : const Icon(Icons.person_outline, color: Colors.grey),
      ),
    );
  }
}
