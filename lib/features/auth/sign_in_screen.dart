import 'package:flutter/material.dart';
import './widgets/google_sign_in_button.dart';
import '../home/home_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'SEOBI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                GoogleSignInButton(
                  onSuccess: () async {
                    // 메인 화면으로 이동하고 로그인 화면은 스택에서 제거
                    await Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  onFail: (message) {
                    // 에러 메시지는 이미 GoogleSignInButton에서 표시됨
                    debugPrint('로그인 실패: $message');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}