import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'package:seobi_app/services/auth/auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final String text;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const GoogleSignInButton({
    super.key,
    this.text = 'Google 계정으로 로그인',
    this.onSuccess,
    this.onFailure,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _handleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signIn();

      if (result.success) {
        widget.onSuccess?.call();
      } else {
        widget.onFailure?.call();
      }
    } catch (e) {
      widget.onFailure?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonLightBg,
          foregroundColor: AppColors.textLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFADB3BC)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textLight,
                    ),
                  ),
                )
                : Stack(
                  children: [
                    // 로고 (좌측 정렬)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SvgPicture.asset(
                        'assets/google_logo.svg',
                        width: 34,
                        height: 34,
                      ),
                    ),
                    // 텍스트 (중앙 정렬)
                    Center(
                      child: Text(
                        widget.text,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.08,
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
