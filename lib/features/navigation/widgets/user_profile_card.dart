import 'package:flutter/material.dart';
import '../../../services/auth/models/auth_result.dart';

class UserProfileCard extends StatelessWidget {
  final UserInfo userInfo;

  const UserProfileCard({
    super.key,
    required this.userInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  userInfo.photoUrl != null ? NetworkImage(userInfo.photoUrl!) : null,
              radius: 24,
              child: userInfo.photoUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userInfo.displayName ?? '사용자',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userInfo.email,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
