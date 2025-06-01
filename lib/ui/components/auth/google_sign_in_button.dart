import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';
import 'package:seobi_app/ui/components/auth/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class GoogleSignInButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return _GoogleSignInButtonContent(
      text: text,
      onSuccess: onSuccess,
      onFailure: onFailure,
    );
  }
}

class _GoogleSignInButtonContent extends StatelessWidget {
  final String text;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const _GoogleSignInButtonContent({
    required this.text,
    this.onSuccess,
    this.onFailure,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AuthViewModel>(context);
    final bool isLoading = viewModel.isLoading;
    
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _handleSignIn(context),
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
        child: isLoading
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
                      text,
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
  
  Future<void> _handleSignIn(BuildContext context) async {
    final viewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    try {
      final result = await viewModel.signIn();

      if (result.success) {
        onSuccess?.call();
      } else {
        onFailure?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      onFailure?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
