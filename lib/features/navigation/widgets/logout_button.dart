import 'package:flutter/material.dart';
import 'dart:async';
import 'package:seobi_app/features/auth/google_sign_in_api.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({super.key});

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> with SingleTickerProviderStateMixin {
  bool _isConfirmMode = false;
  Timer? _confirmTimer;
  late final AnimationController _animationController;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startConfirmationMode() {
    setState(() {
      _isConfirmMode = true;
    });
    _animationController.forward();

    _confirmTimer?.cancel();
    _confirmTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isConfirmMode = false;
        });
        _animationController.reverse();
      }
    });
  }

  Future<void> _handleTap() async {
    if (!_isConfirmMode) {
      _startConfirmationMode();
    } else {
      // 실제 로그아웃 수행
      final authService = GoogleSignInApi();
      await authService.signOut();
      
      // 타이머 취소
      _confirmTimer?.cancel();
      
      if (mounted) {
        setState(() {
          _isConfirmMode = false;
        });
        _animationController.reverse();

        // 로그인 화면으로 이동
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/sign-in',
          (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _confirmTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonHeight = 40.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: buttonHeight,
      constraints: BoxConstraints(
        minWidth: buttonHeight,
        maxWidth: _isConfirmMode ? 120 : buttonHeight,
      ),
      decoration: BoxDecoration(
        color: _isConfirmMode ? Colors.red.shade100 : Colors.transparent,
        borderRadius: BorderRadius.circular(buttonHeight / 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(buttonHeight / 2),
          onTap: _handleTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (buttonHeight - 24) / 2,
              vertical: (buttonHeight - 24) / 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    Icons.logout,
                    color: _isConfirmMode ? Colors.red : Theme.of(context).iconTheme.color,
                    size: 24,
                  ),
                ),
                ClipRect(
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isConfirmMode ? 70 : 0,
                      curve: Curves.easeInOut,
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: const [Colors.white, Colors.transparent],
                            stops: const [0.8, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: _isConfirmMode
                            ? const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  '로그아웃',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  softWrap: false,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
