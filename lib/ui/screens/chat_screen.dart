import 'package:flutter/material.dart';
import '../components/sign_in_bottom_sheet.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  void _showSignInBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SignInBottomSheet(
            onGoogleSignIn: () {
              print('Google 로그인이 시도되었습니다.');
              Navigator.pop(context);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => _showSignInBottomSheet(context),
        child: const Text('로그인 바텀 시트 열기'),
      ),
    );
  }
}
