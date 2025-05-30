import 'package:flutter/material.dart';
import '../../services/auth/auth_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'google_sign_in_button.dart';

class SignInBottomSheet extends StatefulWidget {
  const SignInBottomSheet({super.key});

  @override
  State<SignInBottomSheet> createState() => _SignInBottomSheetState();
}

class _SignInBottomSheetState extends State<SignInBottomSheet> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (_authService.isLoggedIn && mounted) {
      // 로그인 성공 시 바텀 시트 닫기
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isLandscape ? 12 : 0),
          bottomRight: Radius.circular(isLandscape ? 12 : 0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 29),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: screenWidth > 430 ? 370 : screenWidth - 60,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '지금 시작해볼까요?',
                      style: TextStyle(
                        color: Color(0xFF4F4F4F),
                        fontSize: 26,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '바로 가입하고 AI 비서를 만나보세요',
                      style: TextStyle(
                        color: Color(0xFF7D7D7D),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.08,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GoogleSignInButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
