import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seobi_app/ui/constants/app_colors.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = 'Google 계정으로 로그인',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
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
        child: Stack(
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
}
