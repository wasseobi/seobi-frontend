import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SendMessageButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const SendMessageButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 53,
        height: 53,
        decoration: BoxDecoration(
          color: AppTheme.accentBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child:
              isLoading
                  ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Icon(Icons.send, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
