import 'package:flutter/material.dart';
import 'package:seobi_app/services/auth/auth_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'google_sign_in_button.dart';

class SignInBottomSheet extends StatefulWidget {
  final VoidCallback? onSignInComplete;

  const SignInBottomSheet({super.key, this.onSignInComplete});

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
      if (widget.onSignInComplete != null) {
        widget.onSignInComplete!();
      }
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '로그인 중 오류가 발생했습니다: $e',
              style: PretendardStyles.regular12.copyWith(
                color: AppColors.white100,
              ),
            ),
            backgroundColor: AppColors.gray100,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white80,
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
                    Text(
                      '지금 시작해볼까요?',
                      style: PretendardStyles.semiBold26.copyWith(
                        color: AppColors.textLightPrimary,
                        letterSpacing: -0.13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '바로 가입하고 AI 비서를 만나보세요',
                      style: PretendardStyles.semiBold16.copyWith(
                        color: AppColors.textLightSecondary,
                        letterSpacing: -0.08,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GoogleSignInButton(
                      onSuccess: widget.onSignInComplete,
                      onFailure: () {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '로그인에 실패했습니다. 다시 시도해주세요.',
                                style: PretendardStyles.regular12.copyWith(
                                  color: AppColors.white100,
                                ),
                              ),
                              backgroundColor: AppColors.gray100,
                            ),
                          );
                        }
                      },
                    ),
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
