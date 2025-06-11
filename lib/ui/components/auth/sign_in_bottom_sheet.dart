import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seobi_app/ui/components/auth/auth_viewmodel.dart';
import 'google_sign_in_button.dart';

class SignInBottomSheet extends StatelessWidget {
  const SignInBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // 상위 위젯에서 제공하는 AuthViewModel을 사용합니다
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: const _SignInBottomSheetContent(),
    );
  }
}

class _SignInBottomSheetContent extends StatefulWidget {
  const _SignInBottomSheetContent();

  @override
  State<_SignInBottomSheetContent> createState() =>
      _SignInBottomSheetContentState();
}

class _SignInBottomSheetContentState extends State<_SignInBottomSheetContent> {
  late AuthViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<AuthViewModel>(context, listen: false);
    _viewModel.addListener(_checkAuthState);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_checkAuthState);
    super.dispose();
  }

  void _checkAuthState() {
    if (_viewModel.isLoggedIn && mounted) {
      // 로그인 성공 시 바텀 시트 닫기
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final radius = (Theme.of(context).bottomSheetTheme.shape as RoundedRectangleBorder?)?.borderRadius as BorderRadius;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.only(
          topLeft: radius.topLeft,
          topRight: radius.topRight,
          bottomLeft: Radius.circular(isLandscape ? radius.bottomLeft.x : 0),
          bottomRight: Radius.circular(isLandscape ? radius.bottomRight.x : 0),
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
                      '바로 가입하고 서비를 만나보세요',
                      style: TextStyle(
                        color: Color(0xFF7D7D7D),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.08,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // ViewModel은 이미 Provider에 의해 제공됨
                    const GoogleSignInButton(),
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
